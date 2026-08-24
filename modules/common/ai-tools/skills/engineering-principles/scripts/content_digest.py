#!/usr/bin/env python3
"""Hash an exact Git worktree, index, or commit delta without moving refs."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import subprocess
import sys
import tempfile
from dataclasses import dataclass
from pathlib import Path

TOOL_VERSION = "2"
EMPTY_TREE = "4b825dc642cb6eb9a060e54bf8d69288fbee4904"
EXIT_DIGEST_MISMATCH = 1
EXIT_GIT_ERROR = 3
EXIT_NO_CHANGES = 4

# Git reads these variables to locate a repository. An inherited value would
# silently digest a different repository, so the child environment drops them.
# Repository targeting stays explicit through "git -C" and GIT_INDEX_FILE.
LOCATION_ENV = (
    "GIT_ALTERNATE_OBJECT_DIRECTORIES",
    "GIT_COMMON_DIR",
    "GIT_DIR",
    "GIT_INDEX_FILE",
    "GIT_OBJECT_DIRECTORY",
    "GIT_WORK_TREE",
)

RAW_FLAGS = (
    "--raw",
    "-z",
    "--full-index",
    "--abbrev=64",
    "--no-renames",
    "--no-ext-diff",
    "--no-textconv",
)


def is_zero_oid(oid: bytes) -> bool:
    return bool(oid) and all(byte == ord("0") for byte in oid)


@dataclass(frozen=True)
class Change:
    old_mode: bytes
    new_mode: bytes
    old_oid: bytes
    new_oid: bytes
    status: bytes
    old_path: bytes
    new_path: bytes


def git(*args: str, repo: Path, index: Path | None = None) -> bytes:
    env = os.environ.copy()
    for name in LOCATION_ENV:
        env.pop(name, None)
    env.update(
        {
            "GIT_CONFIG_NOSYSTEM": "1",
            "GIT_CONFIG_GLOBAL": os.devnull,
            "GIT_OPTIONAL_LOCKS": "0",
            "LC_ALL": "C",
        }
    )
    if index is not None:
        env["GIT_INDEX_FILE"] = str(index)
    command = [
        "git",
        "-C",
        str(repo),
        "-c",
        "diff.external=",
        "-c",
        "diff.renames=false",
        "-c",
        "core.quotePath=false",
        *args,
    ]
    try:
        return subprocess.check_output(command, env=env, stderr=subprocess.PIPE)
    except subprocess.CalledProcessError as error:
        message = error.stderr.decode("utf-8", "replace").strip()
        raise RuntimeError(message or "git command failed") from error


def parse_raw(raw: bytes) -> list[Change]:
    fields = raw.split(b"\0")
    changes: list[Change] = []
    index = 0
    while index < len(fields) and fields[index]:
        header = fields[index]
        index += 1
        parts = header.split(b" ", 4)
        if len(parts) != 5 or parts[4] == b"U":
            raise RuntimeError("unmerged or malformed Git change")
        if index >= len(fields):
            raise RuntimeError("Git change omitted path")
        old_path = fields[index]
        index += 1
        status = parts[4][:1]
        new_path = old_path
        if status in {b"R", b"C"}:
            if index >= len(fields):
                raise RuntimeError("Git rename omitted destination path")
            new_path = fields[index]
            index += 1
        changes.append(Change(*parts[:4], status, old_path, new_path))
    return changes


def blob(oid: bytes, mode: bytes, repo: Path) -> bytes:
    if not oid or is_zero_oid(oid):
        return b""
    if mode == b"160000":
        return b""
    return git("cat-file", "blob", oid.decode("ascii"), repo=repo)


def record(
    path: bytes,
    mode: bytes,
    oid: bytes,
    side: bytes,
    repo: Path,
) -> bytes:
    content = blob(oid, mode, repo)
    values = (side, path, mode, oid, content)
    return b"".join(len(value).to_bytes(8, "big") + value for value in values)


def digest(changes: list[Change], repo: Path) -> str:
    records: list[bytes] = []
    for change in changes:
        if not is_zero_oid(change.old_oid):
            records.append(
                record(change.old_path, change.old_mode, change.old_oid, b"D", repo)
            )
        if not is_zero_oid(change.new_oid):
            records.append(
                record(change.new_path, change.new_mode, change.new_oid, b"A", repo)
            )
    hasher = hashlib.sha256()
    for item in sorted(records):
        hasher.update(len(item).to_bytes(8, "big"))
        hasher.update(item)
    return hasher.hexdigest()


def head_exists(repo: Path) -> bool:
    try:
        git("rev-parse", "--verify", "HEAD", repo=repo)
    except RuntimeError:
        return False
    return True


def tree_oid(revision: str, repo: Path) -> str:
    # An unborn HEAD has no tree. The empty tree keeps the first slice diffable.
    if revision == "HEAD" and not head_exists(repo):
        return EMPTY_TREE
    resolved = git("rev-parse", "--verify", f"{revision}^{{tree}}", repo=repo)
    return resolved.strip().decode("ascii")


def index_delta(base: str, repo: Path, index: Path | None = None) -> tuple[str, int]:
    raw = git("diff", "--cached", *RAW_FLAGS, base, "--", repo=repo, index=index)
    changes = parse_raw(raw)
    return digest(changes, repo), len(changes)


def staged(repo: Path) -> tuple[str, int]:
    return index_delta(tree_oid("HEAD", repo), repo)


def worktree(base: str, repo: Path) -> tuple[str, int]:
    base_tree = tree_oid(base, repo)
    with tempfile.TemporaryDirectory() as scratch:
        # A scratch index records untracked files without staging them. Git
        # writes the new blobs into the object database. Refs, the real index,
        # and the worktree stay unchanged.
        index = Path(scratch) / "index"
        git("read-tree", base_tree, repo=repo, index=index)
        git("add", "--all", repo=repo, index=index)
        return index_delta(base_tree, repo, index)


def committed(commit: str, repo: Path) -> tuple[str, int]:
    commit_oid = git("rev-parse", "--verify", f"{commit}^{{commit}}", repo=repo).strip()
    parents = git(
        "rev-list", "--parents", "-n", "1", commit_oid.decode("ascii"), repo=repo
    )
    parent_parts = parents.split()
    if len(parent_parts) >= 2:
        # A merge commit digests the first-parent diff only.
        parent = parent_parts[1]
        raw = git(
            "diff-tree",
            "-r",
            *RAW_FLAGS,
            parent.decode("ascii"),
            commit_oid.decode("ascii"),
            "--",
            repo=repo,
        )
    else:
        raw = git(
            "diff-tree",
            "-r",
            "--root",
            "--no-commit-id",
            *RAW_FLAGS,
            commit_oid.decode("ascii"),
            "--",
            repo=repo,
        )
    changes = parse_raw(raw)
    return digest(changes, repo), len(changes)


def fail(message: str, code: int) -> int:
    print(f"content-digest: {message}", file=sys.stderr)
    return code


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--version",
        action="version",
        version=f"content-digest {TOOL_VERSION}",
    )
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--staged", action="store_true")
    mode.add_argument("--committed", metavar="COMMIT")
    mode.add_argument("--worktree", metavar="BASE", nargs="?", const="HEAD")
    parser.add_argument("--repo", type=Path, default=Path.cwd())
    parser.add_argument("--expected-digest")
    args = parser.parse_args()
    try:
        if args.staged:
            name = "staged"
            value, changes = staged(args.repo)
        elif args.committed is not None:
            name = "committed"
            value, changes = committed(args.committed, args.repo)
        else:
            name = "worktree"
            value, changes = worktree(args.worktree, args.repo)
    except (OSError, RuntimeError) as error:
        return fail(str(error), EXIT_GIT_ERROR)
    if changes == 0:
        return fail(
            f"no changes were found for the selected mode: {name}",
            EXIT_NO_CHANGES,
        )
    result = {
        "mode": name,
        "digest": value,
        "changes": changes,
    }
    if args.expected_digest is not None:
        result["digest_match"] = value == args.expected_digest
    print(json.dumps(result, sort_keys=True))
    return 0 if result.get("digest_match", True) else EXIT_DIGEST_MISMATCH


if __name__ == "__main__":
    raise SystemExit(main())
