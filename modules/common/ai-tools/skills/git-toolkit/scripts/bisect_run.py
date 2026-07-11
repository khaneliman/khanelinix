#!/usr/bin/env python3
"""Run an automated Git bisect inside a disposable linked worktree."""

from __future__ import annotations

import argparse
import json
import os
import shlex
import shutil
import signal
import subprocess
import sys
import tempfile
import threading
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Callable, ContextManager, Sequence

SCHEMA_VERSION = 1
DEFAULT_MAX_TESTED_REVISIONS = 100
DEFAULT_MAX_BODY_CHARS = 4000
DEFAULT_MAX_BISECT_OUTPUT_BYTES = 16 * 1024
INTERNAL_RUN_TEST = "--internal-run-test"


class BisectError(RuntimeError):
    """Raised when an isolated bisect cannot complete safely."""


GitRunner = Callable[[Path, Sequence[str], bool], subprocess.CompletedProcess[bytes]]
TemporaryDirectoryFactory = Callable[..., ContextManager[str]]
ExecutableResolver = Callable[[str], str | None]


@dataclass(frozen=True)
class BoundedCommandResult:
    returncode: int
    stdout: bytes
    stderr: bytes
    stdout_bytes_total: int
    stderr_bytes_total: int

    def report(self) -> dict[str, Any]:
        stdout_omitted = self.stdout_bytes_total - len(self.stdout)
        stderr_omitted = self.stderr_bytes_total - len(self.stderr)
        return {
            "capture": "tail",
            "stdout": self.stdout.decode("utf-8", errors="replace"),
            "stdout_bytes_total": self.stdout_bytes_total,
            "stdout_bytes_omitted": stdout_omitted,
            "stdout_truncated": stdout_omitted > 0,
            "stderr": self.stderr.decode("utf-8", errors="replace"),
            "stderr_bytes_total": self.stderr_bytes_total,
            "stderr_bytes_omitted": stderr_omitted,
            "stderr_truncated": stderr_omitted > 0,
        }


class TailCapture:
    def __init__(self, maximum_bytes: int):
        self.maximum_bytes = maximum_bytes
        self.data = bytearray()
        self.total = 0

    def add(self, chunk: bytes) -> None:
        self.total += len(chunk)
        if len(chunk) >= self.maximum_bytes:
            self.data[:] = chunk[-self.maximum_bytes :]
            return
        excess = len(self.data) + len(chunk) - self.maximum_bytes
        if excess > 0:
            del self.data[:excess]
        self.data.extend(chunk)


def decode(value: bytes) -> str:
    return value.decode("utf-8", errors="surrogateescape")


def run_git(
    repository: Path,
    arguments: Sequence[str],
    check: bool = True,
) -> subprocess.CompletedProcess[bytes]:
    environment = os.environ.copy()
    environment.update({"LC_ALL": "C"})
    try:
        result = subprocess.run(
            ["git", "-C", str(repository), *arguments],
            check=False,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            env=environment,
        )
    except OSError as error:
        raise BisectError(f"could not run git: {error}") from error

    if check and result.returncode != 0:
        detail = decode(result.stderr).strip() or "unknown git error"
        raise BisectError(f"git {' '.join(arguments)} failed: {detail}")
    return result


def bounded_completed_result(
    result: subprocess.CompletedProcess[bytes], maximum_bytes: int
) -> BoundedCommandResult:
    stdout = TailCapture(maximum_bytes)
    stderr = TailCapture(maximum_bytes)
    stdout.add(result.stdout or b"")
    stderr.add(result.stderr or b"")
    return BoundedCommandResult(
        returncode=result.returncode,
        stdout=bytes(stdout.data),
        stderr=bytes(stderr.data),
        stdout_bytes_total=stdout.total,
        stderr_bytes_total=stderr.total,
    )


def terminate_process_group(process: subprocess.Popen[bytes]) -> None:
    try:
        os.killpg(process.pid, signal.SIGTERM)
    except OSError:
        try:
            process.terminate()
        except ProcessLookupError:
            pass
    try:
        process.wait(timeout=5)
    except subprocess.TimeoutExpired:
        try:
            os.killpg(process.pid, signal.SIGKILL)
        except OSError:
            try:
                process.kill()
            except ProcessLookupError:
                pass
        process.wait()


def run_git_bounded(
    repository: Path,
    arguments: Sequence[str],
    maximum_bytes: int,
) -> BoundedCommandResult:
    """Run Git while retaining only deterministic tails of stdout and stderr."""

    environment = os.environ.copy()
    environment.update({"LC_ALL": "C"})
    try:
        process = subprocess.Popen(
            ["git", "-C", str(repository), *arguments],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            env=environment,
            start_new_session=True,
        )
    except OSError as error:
        raise BisectError(f"could not run git: {error}") from error

    assert process.stdout is not None
    assert process.stderr is not None
    stdout = TailCapture(maximum_bytes)
    stderr = TailCapture(maximum_bytes)
    reader_errors: list[OSError] = []

    def drain(stream: Any, capture: TailCapture) -> None:
        try:
            while chunk := stream.read(64 * 1024):
                capture.add(chunk)
        except OSError as error:
            reader_errors.append(error)
        finally:
            stream.close()

    threads = [
        threading.Thread(target=drain, args=(process.stdout, stdout), daemon=True),
        threading.Thread(target=drain, args=(process.stderr, stderr), daemon=True),
    ]
    for thread in threads:
        thread.start()
    try:
        returncode = process.wait()
    except BaseException:
        terminate_process_group(process)
        raise
    finally:
        for thread in threads:
            thread.join()

    if reader_errors:
        raise BisectError(f"could not capture git bisect output: {reader_errors[0]}")
    return BoundedCommandResult(
        returncode=returncode,
        stdout=bytes(stdout.data),
        stderr=bytes(stderr.data),
        stdout_bytes_total=stdout.total,
        stderr_bytes_total=stderr.total,
    )


def preflight_test_command(
    worktree: Path,
    test_command: Sequence[str],
    executable_resolver: ExecutableResolver = shutil.which,
) -> None:
    executable = test_command[0]
    if "/" not in executable:
        if executable_resolver(executable) is None:
            raise BisectError(f"test command executable is not available: {executable}")
        return

    path = Path(executable)
    candidate = path if path.is_absolute() else worktree / path
    if not candidate.is_file():
        raise BisectError(f"test command executable does not exist: {executable}")
    if not os.access(candidate, os.X_OK):
        raise BisectError(f"test command is not executable: {executable}")


def wrapped_test_command(test_command: Sequence[str]) -> list[str]:
    return [
        sys.executable,
        str(Path(__file__).resolve()),
        INTERNAL_RUN_TEST,
        *test_command,
    ]


def run_internal_test(
    test_command: Sequence[str],
    runner: Callable[..., subprocess.CompletedProcess[Any]] = subprocess.run,
) -> int:
    if not test_command:
        print("error: internal bisect test command is empty", file=sys.stderr)
        return 128
    try:
        result = runner(list(test_command), check=False)
    except OSError as error:
        print(f"error: could not execute bisect test command: {error}", file=sys.stderr)
        return 128
    if result.returncode in {126, 127}:
        print(
            f"error: bisect test command returned {result.returncode}; aborting",
            file=sys.stderr,
        )
        return 128
    return result.returncode


def git_text(
    runner: GitRunner,
    repository: Path,
    arguments: Sequence[str],
    check: bool = True,
) -> str:
    return decode(runner(repository, arguments, check).stdout).strip()


def parse_skipped_commits(bisect_log: str) -> list[str]:
    skipped: set[str] = set()
    for line in bisect_log.splitlines():
        if not line.startswith("git bisect skip "):
            continue
        try:
            fields = shlex.split(line)
        except ValueError:
            continue
        skipped.update(field for field in fields[3:] if field != "--")
    return sorted(skipped)


def parse_tested_revisions(bisect_log: str) -> list[dict[str, str]]:
    """Return verdicts in the order recorded by `git bisect log`."""

    tested: list[dict[str, str]] = []
    for line in bisect_log.splitlines():
        if not line.startswith("git bisect "):
            continue
        try:
            fields = shlex.split(line)
        except ValueError:
            continue
        if len(fields) < 4 or fields[2] not in {"bad", "good", "skip"}:
            continue
        verdict = fields[2]
        tested.extend(
            {"sha": field, "verdict": verdict} for field in fields[3:] if field != "--"
        )
    return tested


def commit_summary(
    runner: GitRunner,
    repository: Path,
    commit: str,
    maximum_body_chars: int = DEFAULT_MAX_BODY_CHARS,
) -> dict[str, Any]:
    raw = runner(
        repository,
        ["show", "--no-patch", "--format=%H%x00%s%x00%b", commit],
        True,
    ).stdout
    fields = raw.split(b"\0", 2)
    if len(fields) != 3:
        raise BisectError(f"unexpected metadata for commit {commit}")
    body = decode(fields[2]).rstrip("\n")
    selected_body = body if maximum_body_chars == 0 else body[:maximum_body_chars]
    omitted = len(body) - len(selected_body)
    return {
        "body": selected_body,
        "body_chars_omitted": omitted,
        "body_chars_total": len(body),
        "body_truncated": omitted > 0,
        "sha": decode(fields[0]),
        "subject": decode(fields[1]),
    }


def run_bisect(
    repository: Path,
    good: str,
    bad: str,
    test_command: Sequence[str],
    maximum_tested_revisions: int = DEFAULT_MAX_TESTED_REVISIONS,
    maximum_body_chars: int = DEFAULT_MAX_BODY_CHARS,
    maximum_bisect_output_bytes: int = DEFAULT_MAX_BISECT_OUTPUT_BYTES,
    git: GitRunner | None = None,
    temporary_directory: TemporaryDirectoryFactory = tempfile.TemporaryDirectory,
    executable_resolver: ExecutableResolver = shutil.which,
) -> dict[str, Any]:
    """Run bisect in an isolated worktree and restore all Git state."""

    if not test_command:
        raise BisectError("test command is required")
    if maximum_tested_revisions < 0 or maximum_body_chars < 0:
        raise BisectError("report limits must be zero or greater")
    if maximum_bisect_output_bytes < 1:
        raise BisectError("maximum bisect output bytes must be positive")

    runner = git or run_git
    root = Path(
        git_text(runner, repository, ["rev-parse", "--show-toplevel"])
    ).resolve()
    original_head = git_text(
        runner,
        root,
        ["rev-parse", "--verify", "--end-of-options", "HEAD^{commit}"],
    )
    original_status = runner(
        root,
        ["status", "--porcelain=v1", "-z", "--untracked-files=all"],
        True,
    ).stdout
    if original_status:
        raise BisectError("main worktree must be clean, including untracked files")

    good_sha = git_text(
        runner,
        root,
        ["rev-parse", "--verify", "--end-of-options", f"{good}^{{commit}}"],
    )
    bad_sha = git_text(
        runner,
        root,
        ["rev-parse", "--verify", "--end-of-options", f"{bad}^{{commit}}"],
    )
    ancestry = runner(
        root,
        ["merge-base", "--is-ancestor", good_sha, bad_sha],
        False,
    )
    if ancestry.returncode == 1:
        raise BisectError("good revision must be an ancestor of bad revision")
    if ancestry.returncode != 0:
        detail = decode(ancestry.stderr).strip() or "could not verify ancestry"
        raise BisectError(detail)

    report: dict[str, Any] | None = None
    with temporary_directory(prefix="git-bisect-run-") as temporary_root:
        worktree = Path(temporary_root) / "worktree"
        worktree_added = False
        bisect_started = False
        cleanup_errors: list[str] = []
        try:
            runner(root, ["worktree", "add", "--detach", str(worktree), bad_sha], True)
            worktree_added = True
            preflight_test_command(worktree, test_command, executable_resolver)
            runner(worktree, ["bisect", "start", bad_sha, good_sha], True)
            bisect_started = True

            bisect_arguments = ["bisect", "run", *wrapped_test_command(test_command)]
            if git is None:
                result = run_git_bounded(
                    worktree,
                    bisect_arguments,
                    maximum_bisect_output_bytes,
                )
            else:
                result = bounded_completed_result(
                    runner(worktree, bisect_arguments, False),
                    maximum_bisect_output_bytes,
                )
            bisect_log = git_text(runner, worktree, ["bisect", "log"])
            if result.returncode != 0:
                detail = decode(result.stderr).strip() or decode(result.stdout).strip()
                if not detail:
                    detail = "git bisect run did not identify one first bad commit"
                if result.stderr_bytes_total > len(
                    result.stderr
                ) or result.stdout_bytes_total > len(result.stdout):
                    detail += (
                        " (captured tails: "
                        f"stdout {len(result.stdout)}/{result.stdout_bytes_total} bytes, "
                        f"stderr {len(result.stderr)}/{result.stderr_bytes_total} bytes)"
                    )
                raise BisectError(detail)

            first_bad_sha = git_text(
                runner,
                worktree,
                [
                    "rev-parse",
                    "--verify",
                    "--end-of-options",
                    "refs/bisect/bad^{commit}",
                ],
            )
            tested_revisions = parse_tested_revisions(bisect_log)
            selected_revisions = (
                tested_revisions
                if maximum_tested_revisions == 0
                else tested_revisions[-maximum_tested_revisions:]
            )
            skipped_commits = parse_skipped_commits(bisect_log)
            selected_skips = (
                skipped_commits
                if maximum_tested_revisions == 0
                else skipped_commits[:maximum_tested_revisions]
            )
            report = {
                "bad": {"input": bad, "sha": bad_sha},
                "bisect_output": result.report(),
                "first_bad_commit": commit_summary(
                    runner,
                    worktree,
                    first_bad_sha,
                    maximum_body_chars,
                ),
                "good": {"input": good, "sha": good_sha},
                "repository": str(root),
                "schema_version": SCHEMA_VERSION,
                "skipped_commits": selected_skips,
                "skipped_commits_omitted": len(skipped_commits) - len(selected_skips),
                "test_command": list(test_command),
                "tested_revisions": selected_revisions,
                "tested_revisions_omitted": len(tested_revisions)
                - len(selected_revisions),
            }
        finally:
            active_error = sys.exc_info()[0] is not None
            if bisect_started:
                reset = runner(worktree, ["bisect", "reset"], False)
                if reset.returncode != 0:
                    cleanup_errors.append(
                        decode(reset.stderr).strip() or "git bisect reset failed"
                    )
            if worktree_added:
                remove = runner(
                    root,
                    ["worktree", "remove", "--force", str(worktree)],
                    False,
                )
                if remove.returncode != 0:
                    cleanup_errors.append(
                        decode(remove.stderr).strip() or "git worktree remove failed"
                    )
            if cleanup_errors:
                cleanup_detail = "; ".join(cleanup_errors)
                if active_error:
                    print(
                        f"warning: cleanup incomplete: {cleanup_detail}",
                        file=sys.stderr,
                    )
                else:
                    raise BisectError(f"cleanup incomplete: {cleanup_detail}")

    current_head = git_text(
        runner,
        root,
        ["rev-parse", "--verify", "--end-of-options", "HEAD^{commit}"],
    )
    current_status = runner(
        root,
        ["status", "--porcelain=v1", "-z", "--untracked-files=all"],
        True,
    ).stdout
    if current_head != original_head or current_status != original_status:
        raise BisectError("main worktree changed during isolated bisect")
    if report is None:
        raise BisectError("bisect ended without a report")
    return report


def render_text(report: dict[str, Any]) -> str:
    first_bad = report["first_bad_commit"]
    output = report["bisect_output"]
    lines = [
        f"repository: {report['repository']}",
        f"good: {report['good']['input']} ({report['good']['sha']})",
        f"bad: {report['bad']['input']} ({report['bad']['sha']})",
        f"test: {shlex.join(report['test_command'])}",
        f"first bad: {first_bad['sha']} {first_bad['subject']}",
        (
            "bisect output: "
            f"stdout {output['stdout_bytes_total']} byte(s)"
            f" ({output['stdout_bytes_omitted']} omitted), "
            f"stderr {output['stderr_bytes_total']} byte(s)"
            f" ({output['stderr_bytes_omitted']} omitted)"
        ),
    ]
    if first_bad["body"]:
        lines.extend(f"  {line}" for line in first_bad["body"].splitlines())
    if first_bad["body_chars_omitted"]:
        lines.append(f"  {first_bad['body_chars_omitted']} body character(s) omitted")
    if report["skipped_commits"]:
        lines.append("skipped commits:")
        lines.extend(f"  {commit}" for commit in report["skipped_commits"])
        if report["skipped_commits_omitted"]:
            lines.append(f"  {report['skipped_commits_omitted']} more omitted")
    lines.append(
        f"tested revisions: {len(report['tested_revisions'])} shown"
        + (
            f" ({report['tested_revisions_omitted']} omitted)"
            if report["tested_revisions_omitted"]
            else ""
        )
    )
    lines.extend(
        f"  {revision['verdict']}: {revision['sha']}"
        for revision in report["tested_revisions"]
    )
    return "\n".join(lines) + "\n"


def parse_arguments(argv: Sequence[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Run a deterministic test command through git bisect in a "
            "temporary linked worktree."
        )
    )
    parser.add_argument("--repo", type=Path, default=Path.cwd())
    parser.add_argument("--good", required=True, help="known-good revision")
    parser.add_argument("--bad", required=True, help="known-bad revision")
    parser.add_argument(
        "--format", choices=("json", "text"), default="json", help="output format"
    )
    parser.add_argument(
        "--max-tested-revisions",
        type=int,
        default=DEFAULT_MAX_TESTED_REVISIONS,
        help="maximum tested revisions to include; 0 means unlimited (default: 100)",
    )
    parser.add_argument(
        "--max-body-chars",
        type=int,
        default=DEFAULT_MAX_BODY_CHARS,
        help="maximum first-bad body characters; 0 means unlimited (default: 4000)",
    )
    parser.add_argument(
        "--max-bisect-output-bytes",
        type=int,
        default=DEFAULT_MAX_BISECT_OUTPUT_BYTES,
        help="maximum retained bytes per bisect stdout/stderr tail (default: 16384)",
    )
    parser.add_argument(
        "test_command",
        nargs=argparse.REMAINDER,
        help="test command and arguments; place after --",
    )
    arguments = parser.parse_args(argv)
    if arguments.test_command[:1] == ["--"]:
        arguments.test_command = arguments.test_command[1:]
    if not arguments.test_command:
        parser.error("test command is required after --")
    return arguments


def main(argv: Sequence[str] | None = None) -> int:
    raw_arguments = list(argv) if argv is not None else sys.argv[1:]
    if raw_arguments[:1] == [INTERNAL_RUN_TEST]:
        return run_internal_test(raw_arguments[1:])
    arguments = parse_arguments(raw_arguments)

    previous_sigterm = signal.getsignal(signal.SIGTERM)

    def terminate(_signum: int, _frame: object) -> None:
        raise KeyboardInterrupt

    signal.signal(signal.SIGTERM, terminate)
    try:
        report = run_bisect(
            arguments.repo,
            arguments.good,
            arguments.bad,
            arguments.test_command,
            maximum_tested_revisions=arguments.max_tested_revisions,
            maximum_body_chars=arguments.max_body_chars,
            maximum_bisect_output_bytes=arguments.max_bisect_output_bytes,
        )
    except KeyboardInterrupt:
        print("error: bisect interrupted", file=sys.stderr)
        return 130
    except BisectError as error:
        print(f"error: {error}", file=sys.stderr)
        return 1
    finally:
        signal.signal(signal.SIGTERM, previous_sigterm)

    if arguments.format == "json":
        print(json.dumps(report, indent=2, sort_keys=True, ensure_ascii=False))
    else:
        sys.stdout.write(render_text(report))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
