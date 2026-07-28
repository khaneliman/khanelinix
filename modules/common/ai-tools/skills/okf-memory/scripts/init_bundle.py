#!/usr/bin/env python3
"""Preview or initialize one explicit OKF bundle."""

from __future__ import annotations

import argparse
import json
import os
from dataclasses import dataclass
from datetime import date
from pathlib import Path
from typing import Sequence


@dataclass(frozen=True)
class Change:
    action: str
    path: str


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--bundle-dir", required=True, type=Path)
    parser.add_argument(
        "--gitignore",
        type=Path,
        help="explicit project .gitignore to update for MEMORY.local.md",
    )
    parser.add_argument("--date", default=date.today().isoformat())
    parser.add_argument("--apply", action="store_true")
    return parser


def bundle_files(day: str) -> dict[str, str]:
    return {
        "index.md": """---
type: index
---

# Index

Entry point for durable knowledge. Link concept documents from here.

See also: [MEMORY.local.md](MEMORY.local.md), [log.md](log.md).
""",
        "log.md": f"""---
type: log
---

# Log

Chronological record of bundle updates.

- {day}: bundle created.
""",
        "MEMORY.local.md": """---
type: memory
---

No curated memory yet — see concepts/ for full detail.
""",
    }


def validate_target(bundle_dir: Path, gitignore: Path | None) -> str | None:
    if bundle_dir.is_symlink():
        return f"bundle target must not be a symlink: {bundle_dir}"
    if bundle_dir.exists() and not bundle_dir.is_dir():
        return f"bundle target is not a directory: {bundle_dir}"

    concepts = bundle_dir / "concepts"
    if concepts.is_symlink():
        return f"concepts target must not be a symlink: {concepts}"
    if concepts.exists() and not concepts.is_dir():
        return f"concepts target is not a directory: {concepts}"

    for name in bundle_files("1970-01-01"):
        target = bundle_dir / name
        if target.is_symlink():
            return f"bundle file target must not be a symlink: {target}"
        if target.exists() and not target.is_file():
            return f"bundle file target is not a regular file: {target}"

    if gitignore is not None:
        if gitignore.is_symlink():
            return f"gitignore target must not be a symlink: {gitignore}"
        if not gitignore.parent.is_dir():
            return f"gitignore parent does not exist: {gitignore.parent}"
        if gitignore.exists() and not gitignore.is_file():
            return f"gitignore target is not a regular file: {gitignore}"
        relative = Path(
            os.path.relpath(bundle_dir / "MEMORY.local.md", gitignore.parent)
        )
        if relative.parts and relative.parts[0] == "..":
            return "MEMORY.local.md must be inside the explicit gitignore project root"
    return None


def desired_changes(bundle_dir: Path, gitignore: Path | None) -> list[Change]:
    changes: list[Change] = []
    if not bundle_dir.exists():
        changes.append(Change("create_directory", str(bundle_dir)))
    concepts = bundle_dir / "concepts"
    if not concepts.exists():
        changes.append(Change("create_directory", str(concepts)))
    for name in bundle_files("1970-01-01"):
        target = bundle_dir / name
        if not target.exists():
            changes.append(Change("create_file", str(target)))

    if gitignore is not None:
        relative = Path(
            os.path.relpath(bundle_dir / "MEMORY.local.md", gitignore.parent)
        ).as_posix()
        lines = (
            gitignore.read_text(encoding="utf-8").splitlines()
            if gitignore.exists()
            else []
        )
        if relative not in lines:
            changes.append(Change("append_gitignore", str(gitignore)))
    return changes


def write_new_file(path: Path, content: str) -> None:
    flags = os.O_WRONLY | os.O_CREAT | os.O_EXCL
    flags |= getattr(os, "O_NOFOLLOW", 0)
    try:
        descriptor = os.open(path, flags, 0o666)
    except FileExistsError:
        return
    with os.fdopen(descriptor, "w", encoding="utf-8") as stream:
        stream.write(content)


def append_file(path: Path, content: str) -> None:
    flags = os.O_WRONLY | os.O_APPEND | os.O_CREAT
    flags |= getattr(os, "O_NOFOLLOW", 0)
    descriptor = os.open(path, flags, 0o666)
    with os.fdopen(descriptor, "w", encoding="utf-8") as stream:
        stream.write(content)


def apply_changes(bundle_dir: Path, gitignore: Path | None, day: str) -> None:
    (bundle_dir / "concepts").mkdir(parents=True, exist_ok=True)
    for name, content in bundle_files(day).items():
        target = bundle_dir / name
        if not target.exists():
            write_new_file(target, content)

    if gitignore is None:
        return
    relative = Path(
        os.path.relpath(bundle_dir / "MEMORY.local.md", gitignore.parent)
    ).as_posix()
    existing = gitignore.read_text(encoding="utf-8") if gitignore.exists() else ""
    if relative in existing.splitlines():
        return
    separator = "" if not existing or existing.endswith("\n") else "\n"
    append_file(
        gitignore,
        separator + "# okf-memory: local curated memory\n" + relative + "\n",
    )


def main(argv: Sequence[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    bundle_dir = Path(os.path.abspath(args.bundle_dir.expanduser()))
    gitignore = (
        Path(os.path.abspath(args.gitignore.expanduser())) if args.gitignore else None
    )
    error = validate_target(bundle_dir, gitignore)
    if error:
        parser.error(error)

    changes = desired_changes(bundle_dir, gitignore)
    if args.apply and changes:
        apply_changes(bundle_dir, gitignore, args.date)

    status = "noop" if not changes else ("changed" if args.apply else "changes_pending")
    report = {
        "schema_version": 1,
        "skill": "okf-memory",
        "mode": "apply" if args.apply else "preview",
        "status": status,
        "bundle_dir": str(bundle_dir),
        "changes": [change.__dict__ for change in changes],
    }
    print(json.dumps(report, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
