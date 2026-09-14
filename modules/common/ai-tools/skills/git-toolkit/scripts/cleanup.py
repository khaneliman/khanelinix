#!/usr/bin/env python3
"""Preview or remove one explicitly owned, integrated local branch/worktree."""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
from pathlib import Path


class CleanupError(Exception):
    pass


def git(repo: Path, *args: str, check: bool = True) -> subprocess.CompletedProcess:
    # A hook's GIT_DIR must not redirect an explicit --repo to another checkout.
    env = {
        key: value for key, value in os.environ.items() if not key.startswith("GIT_")
    }
    env["GIT_NO_REPLACE_OBJECTS"] = "1"
    result = subprocess.run(
        ["git", "-C", str(repo), *args], capture_output=True, env=env, check=False
    )
    if check and result.returncode:
        raise CleanupError(result.stderr.decode(errors="replace").strip())
    return result


def output(repo: Path, *args: str) -> str:
    return git(repo, *args).stdout.decode(errors="surrogateescape").strip()


def commit(repo: Path, ref: str) -> str:
    return output(
        repo, "rev-parse", "--verify", "--end-of-options", f"{ref}^{{commit}}"
    )


def ancestor(repo: Path, older: str, newer: str) -> bool:
    result = git(repo, "merge-base", "--is-ancestor", older, newer, check=False)
    if result.returncode not in (0, 1):
        raise CleanupError("cannot establish integration ancestry")
    return result.returncode == 0


def worktrees(repo: Path) -> list[dict[str, str]]:
    records = []
    record: dict[str, str] = {}
    for field in git(repo, "worktree", "list", "--porcelain", "-z").stdout.split(b"\0"):
        if not field:
            if record:
                records.append(record)
                record = {}
            continue
        key, _, value = os.fsdecode(field).partition(" ")
        record[key] = value
    return records


def integration(args: argparse.Namespace, tip: str, target: str) -> str:
    if ancestor(args.repo, tip, target):
        return "ancestor"
    if not (args.source_base and args.landed_commit):
        raise CleanupError(
            "tip is not integrated; squash/rebase requires exact landing evidence"
        )
    base = commit(args.repo, args.source_base)
    landed = commit(args.repo, args.landed_commit)
    if not ancestor(args.repo, base, tip) or not ancestor(args.repo, landed, target):
        raise CleanupError("source base or landing is outside the declared history")
    parents = output(args.repo, "rev-list", "--parents", "-n", "1", landed).split()[1:]
    if len(parents) != 1:
        raise CleanupError("landing evidence must be a single-parent commit")

    def diff(start: str, end: str) -> bytes:
        return git(
            args.repo,
            "diff",
            "--no-ext-diff",
            "--no-textconv",
            "--no-renames",
            "--ignore-submodules=none",
            "--submodule=short",
            "--binary",
            "--full-index",
            "--no-color",
            start,
            end,
            "--",
        ).stdout

    source = diff(base, tip)
    if not source or source != diff(parents[0], landed):
        raise CleanupError("source changes do not exactly match the landed commit")
    return "exact-landed-diff"


def plan(args: argparse.Namespace) -> dict:
    repo = args.repo
    records = worktrees(repo)
    branch_ref = f"refs/heads/{args.branch}" if args.branch else None
    if branch_ref:
        git(repo, "check-ref-format", branch_ref)
        if args.branch.startswith("-"):
            raise CleanupError("branch cannot start with an option prefix")
    path = args.worktree.resolve() if args.worktree else None
    selected = next((r for r in records if Path(r["worktree"]).resolve() == path), None)
    exists = (
        branch_ref
        and git(
            repo, "show-ref", "--verify", "--quiet", branch_ref, check=False
        ).returncode
        == 0
    )
    if path and not selected and path.exists():
        raise CleanupError("path exists but is not a registered worktree")
    if not exists and not selected:
        return {
            "state": "already-clean",
            "branch": args.branch,
            "worktree": str(path) if path else None,
        }

    tip = commit(repo, args.expected_tip)
    if tip != args.expected_tip:
        raise CleanupError("expected tip must be a full commit object ID")
    target_ref = output(
        repo,
        "rev-parse",
        "--symbolic-full-name",
        "--verify",
        "--end-of-options",
        args.target,
    )
    if not target_ref.startswith("refs/heads/") or target_ref == branch_ref:
        raise CleanupError("target must be a different local integration branch")
    target = commit(repo, target_ref)
    if exists and commit(repo, branch_ref) != tip:
        raise CleanupError("branch tip changed since handoff")
    if branch_ref:
        for record in records:
            if record.get("branch") == branch_ref and record is not selected:
                raise CleanupError(
                    "branch is checked out in a worktree outside the exact cleanup target"
                )
    if selected:
        if (
            selected is records[0]
            or repo.resolve().is_relative_to(path)
            or Path.cwd().resolve().is_relative_to(path)
        ):
            raise CleanupError("cannot remove the primary or executing worktree")
        if "locked" in selected or "prunable" in selected:
            raise CleanupError("worktree is locked or unavailable")
        if selected.get("branch") != branch_ref or selected.get("HEAD") != tip:
            raise CleanupError("worktree branch or tip changed since handoff")
        if any(
            entry[:1] == b"S" or entry[:1].islower()
            for entry in git(path, "ls-files", "-v", "-z").stdout.split(b"\0")
            if entry
        ):
            raise CleanupError("worktree index flags may hide tracked changes")
        if git(
            path,
            "status",
            "--porcelain=v1",
            "-z",
            "--untracked-files=all",
            "--ignored",
            "--ignore-submodules=none",
        ).stdout:
            raise CleanupError(
                "worktree contains tracked, untracked, ignored, or submodule changes"
            )
        for marker in (
            "rebase-merge",
            "rebase-apply",
            "MERGE_HEAD",
            "CHERRY_PICK_HEAD",
            "REVERT_HEAD",
            "sequencer",
            "BISECT_START",
        ):
            marker_path = Path(
                output(
                    path, "rev-parse", "--path-format=absolute", "--git-path", marker
                )
            )
            if marker_path.exists():
                raise CleanupError(f"worktree has an unfinished operation: {marker}")
    return {
        "state": "ready",
        "branch": args.branch,
        "worktree": str(path) if selected else None,
        "expected_tip": tip,
        "target": target_ref,
        "target_tip": target,
        "integration": integration(args, tip, target),
        "delete_branch": bool(exists),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo", type=Path, required=True)
    parser.add_argument(
        "--branch", help="exact task-owned local branch; omit for detached worktree"
    )
    parser.add_argument(
        "--worktree", type=Path, help="exact task-owned linked worktree"
    )
    parser.add_argument("--expected-tip", required=True)
    parser.add_argument(
        "--target",
        required=True,
        help="local integration branch, not a remote-tracking ref",
    )
    parser.add_argument(
        "--source-base",
        help="recorded fork-point commit for squash/cherry-pick evidence",
    )
    parser.add_argument(
        "--landed-commit", help="single commit containing the exact source delta"
    )
    parser.add_argument("--apply", action="store_true")
    args = parser.parse_args()
    if not (args.branch or args.worktree):
        parser.error("specify --branch or --worktree")
    try:
        result = plan(args)
        if args.apply and result["state"] == "ready":
            # The parent must stop writers first; Git does not provide a cross-worktree transaction.
            if plan(args) != result:
                raise CleanupError("cleanup inputs changed during validation")
            if result["worktree"]:
                git(args.repo, "worktree", "remove", "--", result["worktree"])
            if result["delete_branch"]:
                if (
                    commit(args.repo, f"refs/heads/{args.branch}")
                    != result["expected_tip"]
                ):
                    raise CleanupError(
                        "branch moved after worktree removal; branch retained"
                    )
                # The target proof above also covers squashes, which branch -d cannot recognize.
                git(args.repo, "branch", "-D", "--", args.branch)
            if plan(args)["state"] != "already-clean":
                raise CleanupError("cleanup readback failed")
            result["state"] = "cleaned"
        print(json.dumps(result, sort_keys=True))
        return 0
    except (CleanupError, OSError) as error:
        print(json.dumps({"state": "blocked", "reason": str(error)}, sort_keys=True))
        return 1


if __name__ == "__main__":
    sys.exit(main())
