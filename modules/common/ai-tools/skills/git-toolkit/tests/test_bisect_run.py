from __future__ import annotations

import contextlib
import importlib.util
import io
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(__file__).parents[1] / "scripts" / "bisect_run.py"
SPEC = importlib.util.spec_from_file_location("bisect_run", SCRIPT)
assert SPEC is not None and SPEC.loader is not None
bisect_run = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = bisect_run
SPEC.loader.exec_module(bisect_run)


def completed(stdout: bytes = b"", stderr: bytes = b"", code: int = 0):
    return subprocess.CompletedProcess([], code, stdout, stderr)


class FakeTemporaryDirectory:
    def __init__(self, **_kwargs) -> None:
        self.path = "/tmp/fake-bisect"

    def __enter__(self) -> str:
        return self.path

    def __exit__(self, *_args) -> None:
        return None


class FakeGit:
    def __init__(self, bisect_result: subprocess.CompletedProcess[bytes]) -> None:
        self.bisect_result = bisect_result
        self.calls: list[tuple[Path, tuple[str, ...], bool]] = []

    def __call__(self, repository: Path, arguments, check: bool):
        args = tuple(arguments)
        self.calls.append((repository, args, check))
        if args == ("rev-parse", "--show-toplevel"):
            return completed(b"/repo\n")
        if args == (
            "rev-parse",
            "--verify",
            "--end-of-options",
            "HEAD^{commit}",
        ):
            return completed(b"original\n")
        if args == (
            "rev-parse",
            "--verify",
            "--end-of-options",
            "refs/bisect/bad^{commit}",
        ):
            return completed(b"first-bad\n")
        if args == (
            "rev-parse",
            "--verify",
            "--end-of-options",
            "good^{commit}",
        ):
            return completed(b"good-sha\n")
        if args == (
            "rev-parse",
            "--verify",
            "--end-of-options",
            "bad^{commit}",
        ):
            return completed(b"bad-sha\n")
        if args == (
            "status",
            "--porcelain=v1",
            "-z",
            "--untracked-files=all",
        ):
            return completed()
        if args == (
            "merge-base",
            "--is-ancestor",
            "good-sha",
            "bad-sha",
        ):
            return completed()
        if args[:3] == ("worktree", "add", "--detach"):
            return completed()
        if args == ("bisect", "start", "bad-sha", "good-sha"):
            return completed()
        if args[:2] == ("bisect", "run") and args[-2:] == ("python3", "test.py"):
            return self.bisect_result
        if args == ("bisect", "log"):
            return completed(
                b"git bisect start 'bad-sha' 'good-sha'\n"
                b"git bisect good tested-good\n"
                b"git bisect skip skipped-sha\n"
                b"git bisect bad first-bad\n"
            )
        if args == (
            "show",
            "--no-patch",
            "--format=%H%x00%s%x00%b",
            "first-bad",
        ):
            return completed(b"first-bad\0break behavior\0reason\n")
        if args == ("bisect", "reset"):
            return completed()
        if args[:3] == ("worktree", "remove", "--force"):
            return completed()
        raise AssertionError(f"unexpected git command: {args}")


class BisectRunTests(unittest.TestCase):
    def test_real_bisect_streams_noisy_output_into_bounded_tail(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            repository = Path(temporary) / "repository"
            repository.mkdir()

            def git(*arguments: str) -> str:
                result = subprocess.run(
                    ["git", "-C", str(repository), *arguments],
                    check=True,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE,
                    text=True,
                )
                return result.stdout.strip()

            git("init", "--initial-branch=main")
            git("config", "user.name", "Test User")
            git("config", "user.email", "test@example.invalid")
            state = repository / "state.txt"
            state.write_text("good\n", encoding="utf-8")
            git("add", "state.txt")
            git("commit", "-m", "known good")
            good = git("rev-parse", "HEAD")
            state.write_text("still good\n", encoding="utf-8")
            git("commit", "-am", "intermediate good")
            state.write_text("bad\n", encoding="utf-8")
            git("commit", "-am", "first bad")
            bad = git("rev-parse", "HEAD")
            command = [
                sys.executable,
                "-c",
                (
                    "from pathlib import Path; "
                    "print('x' * 10000); "
                    "raise SystemExit(1 if Path('state.txt').read_text() == 'bad\\n' else 0)"
                ),
            ]

            report = bisect_run.run_bisect(
                repository,
                good,
                bad,
                command,
                maximum_bisect_output_bytes=128,
            )

            self.assertEqual(report["first_bad_commit"]["sha"], bad)
            output = report["bisect_output"]
            self.assertGreater(output["stdout_bytes_total"], 128)
            self.assertEqual(len(output["stdout"].encode()), 128)
            self.assertTrue(output["stdout_truncated"])
            self.assertEqual(
                git("worktree", "list", "--porcelain").count("worktree "), 1
            )

    def test_success_reports_first_bad_and_always_cleans_up(self) -> None:
        fake = FakeGit(completed())

        report = bisect_run.run_bisect(
            Path("/repo"),
            "good",
            "bad",
            ["python3", "test.py"],
            git=fake,
            temporary_directory=FakeTemporaryDirectory,
        )

        self.assertEqual(report["first_bad_commit"]["sha"], "first-bad")
        self.assertFalse(report["first_bad_commit"]["body_truncated"])
        self.assertEqual(report["skipped_commits"], ["skipped-sha"])
        self.assertEqual(
            report["tested_revisions"],
            [
                {"sha": "tested-good", "verdict": "good"},
                {"sha": "skipped-sha", "verdict": "skip"},
                {"sha": "first-bad", "verdict": "bad"},
            ],
        )
        called = [arguments for _repository, arguments, _check in fake.calls]
        self.assertIn(("bisect", "reset"), called)
        self.assertTrue(
            any(
                arguments[:3] == ("worktree", "remove", "--force")
                for arguments in called
            )
        )

    def test_first_bad_body_is_bounded(self) -> None:
        report = bisect_run.run_bisect(
            Path("/repo"),
            "good",
            "bad",
            ["python3", "test.py"],
            maximum_body_chars=3,
            git=FakeGit(completed()),
            temporary_directory=FakeTemporaryDirectory,
        )

        first_bad = report["first_bad_commit"]
        self.assertEqual(first_bad["body"], "rea")
        self.assertEqual(first_bad["body_chars_total"], 6)
        self.assertEqual(first_bad["body_chars_omitted"], 3)
        self.assertTrue(first_bad["body_truncated"])

    def test_bisect_output_capture_keeps_bounded_tails_and_totals(self) -> None:
        report = bisect_run.run_bisect(
            Path("/repo"),
            "good",
            "bad",
            ["python3", "test.py"],
            maximum_bisect_output_bytes=4,
            git=FakeGit(completed(stdout=b"0123456789", stderr=b"abcdefghij")),
            temporary_directory=FakeTemporaryDirectory,
        )

        output = report["bisect_output"]
        self.assertEqual(output["stdout"], "6789")
        self.assertEqual(output["stdout_bytes_total"], 10)
        self.assertEqual(output["stdout_bytes_omitted"], 6)
        self.assertTrue(output["stdout_truncated"])
        self.assertEqual(output["stderr"], "ghij")
        self.assertEqual(output["stderr_bytes_total"], 10)
        self.assertEqual(output["stderr_bytes_omitted"], 6)
        self.assertTrue(output["stderr_truncated"])

    def test_missing_executable_is_rejected_before_bisect_start(self) -> None:
        fake = FakeGit(completed())

        with self.assertRaisesRegex(bisect_run.BisectError, "not available"):
            bisect_run.run_bisect(
                Path("/repo"),
                "good",
                "bad",
                ["missing-test-command"],
                git=fake,
                temporary_directory=FakeTemporaryDirectory,
                executable_resolver=lambda _name: None,
            )

        called = [arguments for _repository, arguments, _check in fake.calls]
        self.assertFalse(
            any(arguments[:2] == ("bisect", "start") for arguments in called)
        )
        self.assertFalse(
            any(arguments[:2] == ("bisect", "run") for arguments in called)
        )
        self.assertTrue(
            any(
                arguments[:3] == ("worktree", "remove", "--force")
                for arguments in called
            )
        )

    def test_internal_wrapper_aborts_126_and_127_without_changing_other_codes(
        self,
    ) -> None:
        def result(code: int):
            return lambda *_args, **_kwargs: completed(code=code)

        for code in (126, 127):
            with self.subTest(code=code), contextlib.redirect_stderr(io.StringIO()):
                self.assertEqual(
                    bisect_run.run_internal_test(["test"], runner=result(code)),
                    128,
                )
        self.assertEqual(bisect_run.run_internal_test(["test"], runner=result(0)), 0)
        self.assertEqual(bisect_run.run_internal_test(["test"], runner=result(1)), 1)
        self.assertEqual(
            bisect_run.run_internal_test(["test"], runner=result(125)), 125
        )

    def test_failed_run_still_resets_and_removes_worktree(self) -> None:
        fake = FakeGit(completed(stderr=b"test command failed", code=2))

        with self.assertRaisesRegex(bisect_run.BisectError, "test command failed"):
            bisect_run.run_bisect(
                Path("/repo"),
                "good",
                "bad",
                ["python3", "test.py"],
                git=fake,
                temporary_directory=FakeTemporaryDirectory,
            )

        called = [arguments for _repository, arguments, _check in fake.calls]
        self.assertIn(("bisect", "reset"), called)
        self.assertTrue(
            any(
                arguments[:3] == ("worktree", "remove", "--force")
                for arguments in called
            )
        )

    def test_dirty_repository_is_rejected_before_worktree_creation(self) -> None:
        fake = FakeGit(completed())

        def dirty_git(repository: Path, arguments, check: bool):
            if tuple(arguments) == (
                "status",
                "--porcelain=v1",
                "-z",
                "--untracked-files=all",
            ):
                return completed(b"?? untracked\0")
            return fake(repository, arguments, check)

        with self.assertRaisesRegex(bisect_run.BisectError, "must be clean"):
            bisect_run.run_bisect(
                Path("/repo"),
                "good",
                "bad",
                ["python3", "test.py"],
                git=dirty_git,
                temporary_directory=FakeTemporaryDirectory,
            )

        called = [arguments for _repository, arguments, _check in fake.calls]
        self.assertFalse(
            any(arguments[:2] == ("worktree", "add") for arguments in called)
        )

    def test_main_worktree_change_after_cleanup_is_rejected(self) -> None:
        fake = FakeGit(completed())
        root_head_reads = 0

        def changed_main_git(repository: Path, arguments, check: bool):
            nonlocal root_head_reads
            if repository == Path("/repo") and tuple(arguments) == (
                "rev-parse",
                "--verify",
                "--end-of-options",
                "HEAD^{commit}",
            ):
                root_head_reads += 1
                return completed(
                    b"original\n" if root_head_reads == 1 else b"changed\n"
                )
            return fake(repository, arguments, check)

        with self.assertRaisesRegex(bisect_run.BisectError, "main worktree changed"):
            bisect_run.run_bisect(
                Path("/repo"),
                "good",
                "bad",
                ["python3", "test.py"],
                git=changed_main_git,
                temporary_directory=FakeTemporaryDirectory,
            )

        called = [arguments for _repository, arguments, _check in fake.calls]
        self.assertIn(("bisect", "reset"), called)
        self.assertTrue(
            any(
                arguments[:3] == ("worktree", "remove", "--force")
                for arguments in called
            )
        )


if __name__ == "__main__":
    unittest.main()
