#!/usr/bin/env python3
"""Produce a deterministic, read-only report for a Git change stack."""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
from pathlib import Path
from typing import Any, Callable, Sequence

SCHEMA_VERSION = 1
DEFAULT_MAX_COMMITS = 100
DEFAULT_MAX_STATUS_ENTRIES = 100
DEFAULT_MAX_PATHS_PER_COMMIT = 100
DEFAULT_MAX_BODY_CHARS = 4000


class ReportError(RuntimeError):
    """Raised when Git cannot produce a trustworthy report."""


GitRunner = Callable[[Path, Sequence[str], bool], subprocess.CompletedProcess[bytes]]


def run_git(
    repository: Path,
    arguments: Sequence[str],
    check: bool = True,
) -> subprocess.CompletedProcess[bytes]:
    """Run one read-only Git command with locale-stable output."""

    environment = os.environ.copy()
    environment.update({"GIT_OPTIONAL_LOCKS": "0", "LC_ALL": "C"})
    try:
        result = subprocess.run(
            ["git", "-C", str(repository), *arguments],
            check=False,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            env=environment,
        )
    except OSError as error:
        raise ReportError(f"could not run git: {error}") from error

    if check and result.returncode != 0:
        detail = decode(result.stderr).strip() or "unknown git error"
        raise ReportError(f"git {' '.join(arguments)} failed: {detail}")
    return result


def decode(value: bytes) -> str:
    return value.decode("utf-8", errors="surrogateescape")


def git_text(
    runner: GitRunner,
    repository: Path,
    arguments: Sequence[str],
    check: bool = True,
) -> str:
    return decode(runner(repository, arguments, check).stdout).strip()


def parse_status(raw_status: bytes) -> list[dict[str, str]]:
    """Parse `git status --porcelain=v1 -z` without losing unusual paths."""

    records = raw_status.split(b"\0")
    if records and not records[-1]:
        records.pop()

    entries: list[dict[str, str]] = []
    index = 0
    while index < len(records):
        record = records[index]
        index += 1
        if len(record) < 4 or record[2:3] != b" ":
            raise ReportError("unexpected porcelain status record")

        code = decode(record[:2])
        entry = {"code": code, "path": decode(record[3:])}
        if "R" in code or "C" in code:
            if index >= len(records):
                raise ReportError("rename status record is missing its original path")
            entry["original_path"] = decode(records[index])
            index += 1
        entries.append(entry)

    return sorted(
        entries,
        key=lambda entry: (
            entry["path"],
            entry.get("original_path", ""),
            entry["code"],
        ),
    )


def parse_name_status(raw_diff: bytes) -> list[dict[str, str]]:
    """Parse `git diff --name-status -z` records."""

    fields = raw_diff.split(b"\0")
    if fields and not fields[-1]:
        fields.pop()

    paths: list[dict[str, str]] = []
    index = 0
    while index < len(fields):
        status = decode(fields[index])
        index += 1
        if not status or index >= len(fields):
            raise ReportError("unexpected name-status diff record")

        if status[0] in {"R", "C"}:
            if index + 1 >= len(fields):
                raise ReportError("rename diff record is missing a path")
            old_path = decode(fields[index])
            new_path = decode(fields[index + 1])
            index += 2
            paths.append({"old_path": old_path, "path": new_path, "status": status})
        else:
            paths.append({"path": decode(fields[index]), "status": status})
            index += 1

    return sorted(
        paths,
        key=lambda item: (item["path"], item.get("old_path", ""), item["status"]),
    )


def bounded_items(items: Sequence[Any], maximum: int) -> tuple[list[Any], int]:
    selected = list(items if maximum == 0 else items[:maximum])
    return selected, len(items) - len(selected)


def bounded_text(value: str, maximum: int) -> tuple[str, int]:
    selected = value if maximum == 0 else value[:maximum]
    return selected, len(value) - len(selected)


def commit_report(
    runner: GitRunner,
    repository: Path,
    commit: str,
    max_paths: int = DEFAULT_MAX_PATHS_PER_COMMIT,
    max_body_chars: int = DEFAULT_MAX_BODY_CHARS,
) -> dict[str, Any]:
    metadata = runner(
        repository,
        [
            "show",
            "--no-patch",
            "--format=%H%x00%P%x00%an%x00%ae%x00%aI%x00%B",
            commit,
        ],
        True,
    ).stdout
    fields = metadata.split(b"\0", 5)
    if len(fields) != 6:
        raise ReportError(f"unexpected metadata for commit {commit}")

    sha, parents, author_name, author_email, authored_at, raw_message = (
        decode(field) for field in fields
    )
    message = raw_message.rstrip("\n")
    message_lines = message.splitlines()
    subject = message_lines[0] if message_lines else ""
    body = "\n".join(message_lines[1:]).strip("\n")
    parent_shas = parents.split() if parents else []

    if parent_shas:
        diff_arguments = [
            "diff",
            "--name-status",
            "-z",
            "-M",
            "--no-ext-diff",
            parent_shas[0],
            sha,
            "--",
        ]
    else:
        diff_arguments = [
            "diff-tree",
            "--root",
            "--no-commit-id",
            "--name-status",
            "-z",
            "-r",
            "-M",
            sha,
            "--",
        ]

    all_paths = parse_name_status(runner(repository, diff_arguments, True).stdout)
    paths, paths_omitted = bounded_items(all_paths, max_paths)
    selected_body, body_chars_omitted = bounded_text(body, max_body_chars)
    return {
        "author": {
            "email": author_email,
            "name": author_name,
            "timestamp": authored_at,
        },
        "body": selected_body,
        "body_chars_omitted": body_chars_omitted,
        "body_chars_total": len(body),
        "body_truncated": body_chars_omitted > 0,
        "parents": parent_shas,
        "paths": paths,
        "paths_omitted": paths_omitted,
        "paths_total": len(all_paths),
        "paths_truncated": paths_omitted > 0,
        "sha": sha,
        "subject": subject,
    }


def build_report(
    repository: Path,
    base: str,
    head: str,
    max_commits: int = DEFAULT_MAX_COMMITS,
    max_status_entries: int = DEFAULT_MAX_STATUS_ENTRIES,
    max_paths_per_commit: int = DEFAULT_MAX_PATHS_PER_COMMIT,
    max_body_chars: int = DEFAULT_MAX_BODY_CHARS,
    git: GitRunner | None = None,
) -> dict[str, Any]:
    """Collect report data using read-only Git commands only."""

    if (
        min(
            max_commits,
            max_status_entries,
            max_paths_per_commit,
            max_body_chars,
        )
        < 0
    ):
        raise ReportError("report limits must be zero or greater")

    runner = git or run_git
    root = Path(
        git_text(runner, repository, ["rev-parse", "--show-toplevel"])
    ).resolve()
    base_sha = git_text(
        runner,
        root,
        ["rev-parse", "--verify", "--end-of-options", f"{base}^{{commit}}"],
    )
    head_sha = git_text(
        runner,
        root,
        ["rev-parse", "--verify", "--end-of-options", f"{head}^{{commit}}"],
    )
    merge_base = git_text(runner, root, ["merge-base", base_sha, head_sha])

    counts = git_text(
        runner,
        root,
        ["rev-list", "--left-right", "--count", f"{base_sha}...{head_sha}"],
    ).split()
    if len(counts) != 2:
        raise ReportError("unexpected ahead/behind count")

    all_commits = git_text(
        runner,
        root,
        ["rev-list", "--reverse", "--topo-order", f"{base_sha}..{head_sha}"],
    ).splitlines()
    shown_commits = all_commits[-max_commits:] if max_commits else all_commits

    raw_status = runner(
        root,
        ["status", "--porcelain=v1", "-z", "--untracked-files=all"],
        True,
    ).stdout
    branch_result = runner(
        root,
        ["symbolic-ref", "--quiet", "--short", "HEAD"],
        False,
    )
    branch = (
        decode(branch_result.stdout).strip() if branch_result.returncode == 0 else None
    )
    status_entries = parse_status(raw_status)
    shown_status_entries, status_entries_omitted = bounded_items(
        status_entries, max_status_entries
    )

    return {
        "ahead_behind": {
            "base_only": int(counts[0]),
            "head_only": int(counts[1]),
        },
        "base": {"input": base, "sha": base_sha},
        "commits": [
            commit_report(
                runner,
                root,
                commit,
                max_paths=max_paths_per_commit,
                max_body_chars=max_body_chars,
            )
            for commit in shown_commits
        ],
        "commits_omitted": len(all_commits) - len(shown_commits),
        "commits_total": len(all_commits),
        "head": {"input": head, "sha": head_sha},
        "merge_base": merge_base,
        "repository": str(root),
        "schema_version": SCHEMA_VERSION,
        "worktree": {
            "branch": branch,
            "clean": not status_entries,
            "entries": shown_status_entries,
            "entries_omitted": status_entries_omitted,
            "entries_total": len(status_entries),
            "entries_truncated": status_entries_omitted > 0,
        },
    }


def render_text(report: dict[str, Any]) -> str:
    lines = [
        f"repository: {report['repository']}",
        f"base: {report['base']['input']} ({report['base']['sha']})",
        f"head: {report['head']['input']} ({report['head']['sha']})",
        f"merge base: {report['merge_base']}",
        (
            "ahead/behind: "
            f"head +{report['ahead_behind']['head_only']}, "
            f"base +{report['ahead_behind']['base_only']}"
        ),
        (
            "worktree: clean"
            if report["worktree"]["clean"]
            else (
                f"worktree: {len(report['worktree']['entries'])}/"
                f"{report['worktree']['entries_total']} change(s) shown"
            )
        ),
        (
            f"commits: {len(report['commits'])}/{report['commits_total']} shown"
            + (
                f" ({report['commits_omitted']} omitted)"
                if report["commits_omitted"]
                else ""
            )
        ),
    ]

    for entry in report["worktree"]["entries"]:
        original = f" <- {entry['original_path']}" if "original_path" in entry else ""
        lines.append(f"  {entry['code']} {entry['path']}{original}")
    if report["worktree"]["entries_omitted"]:
        lines.append(
            f"  {report['worktree']['entries_omitted']} worktree change(s) omitted"
        )

    for commit in report["commits"]:
        lines.append(f"- {commit['sha']} {commit['subject']}")
        if commit["body"]:
            lines.extend(f"    {line}" for line in commit["body"].splitlines())
        if commit["body_chars_omitted"]:
            lines.append(
                f"    {commit['body_chars_omitted']} body character(s) omitted"
            )
        for path in commit["paths"]:
            old_path = f" <- {path['old_path']}" if "old_path" in path else ""
            lines.append(f"    {path['status']} {path['path']}{old_path}")
        if commit["paths_omitted"]:
            lines.append(f"    {commit['paths_omitted']} path(s) omitted")

    return "\n".join(lines) + "\n"


def parse_arguments(argv: Sequence[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Report status, ahead/behind counts, commit messages, and touched "
            "paths without changing Git state."
        )
    )
    parser.add_argument("--repo", type=Path, default=Path.cwd())
    parser.add_argument("--base", required=True, help="base revision")
    parser.add_argument("--head", default="HEAD", help="head revision (default: HEAD)")
    parser.add_argument(
        "--max-commits",
        type=int,
        default=DEFAULT_MAX_COMMITS,
        help="maximum commits to include; 0 means unlimited (default: 100)",
    )
    parser.add_argument(
        "--max-status-entries",
        type=int,
        default=DEFAULT_MAX_STATUS_ENTRIES,
        help="maximum worktree entries; 0 means unlimited (default: 100)",
    )
    parser.add_argument(
        "--max-paths-per-commit",
        type=int,
        default=DEFAULT_MAX_PATHS_PER_COMMIT,
        help="maximum paths per commit; 0 means unlimited (default: 100)",
    )
    parser.add_argument(
        "--max-body-chars",
        type=int,
        default=DEFAULT_MAX_BODY_CHARS,
        help="maximum body characters per commit; 0 means unlimited (default: 4000)",
    )
    parser.add_argument(
        "--format", choices=("json", "text"), default="json", help="output format"
    )
    return parser.parse_args(argv)


def main(argv: Sequence[str] | None = None) -> int:
    arguments = parse_arguments(argv)
    try:
        report = build_report(
            arguments.repo,
            arguments.base,
            arguments.head,
            max_commits=arguments.max_commits,
            max_status_entries=arguments.max_status_entries,
            max_paths_per_commit=arguments.max_paths_per_commit,
            max_body_chars=arguments.max_body_chars,
        )
    except ReportError as error:
        print(f"error: {error}", file=sys.stderr)
        return 1

    if arguments.format == "json":
        print(json.dumps(report, indent=2, sort_keys=True, ensure_ascii=False))
    else:
        sys.stdout.write(render_text(report))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
