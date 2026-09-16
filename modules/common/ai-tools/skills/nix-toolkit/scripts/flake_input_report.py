#!/usr/bin/env python3
"""Report a flake's locked inputs, their age, and their follows edges."""

from __future__ import annotations

import argparse
import datetime
import json
import subprocess
import sys
from collections.abc import Sequence
from dataclasses import dataclass, field
from typing import Any

DEFAULT_LIMIT = 40


class FlakeInputError(RuntimeError):
    """Raised when flake metadata cannot be read."""


@dataclass
class Input:
    name: str
    reference: str
    revision: str | None = None
    last_modified: int | None = None
    follows: list[str] = field(default_factory=list)
    followed_by: list[str] = field(default_factory=list)

    def age_days(self, now: int) -> int | None:
        if self.last_modified is None:
            return None
        return max(0, (now - self.last_modified) // 86400)


def read_metadata(flake_ref: str) -> dict[str, Any]:
    command = ["nix", "flake", "metadata", "--json", flake_ref]
    try:
        result = subprocess.run(
            command,
            check=False,
            capture_output=True,
            text=True,
            errors="surrogateescape",
        )
    except OSError as error:
        raise FlakeInputError(f"could not run nix: {error}") from error

    _ = sys.stderr.write(result.stderr)
    if result.returncode != 0:
        raise FlakeInputError("could not read flake metadata")

    return json.loads(result.stdout)


def describe(locked: dict[str, Any]) -> str:
    kind = locked.get("type", "unknown")
    if kind == "github" or kind == "gitlab":
        owner = locked.get("owner", "?")
        repo = locked.get("repo", "?")
        reference = f"{kind}:{owner}/{repo}"
    elif kind == "path":
        reference = f"path:{locked.get('path', '?')}"
    else:
        reference = locked.get("url", kind)
    branch = locked.get("ref")
    return f"{reference}#{branch}" if branch else reference


def collect_inputs(metadata: dict[str, Any]) -> list[Input]:
    locks = metadata.get("locks", {})
    nodes: dict[str, Any] = locks.get("nodes", {})
    root = locks.get("root", "root")

    inputs: dict[str, Input] = {}
    for name, node in nodes.items():
        if name == root:
            continue
        locked = node.get("locked", {})
        inputs[name] = Input(
            name=name,
            reference=describe(locked),
            revision=locked.get("rev") or locked.get("narHash"),
            last_modified=locked.get("lastModified"),
        )

    # A string edge names another node directly. A list edge is a `follows`,
    # holding the input path the edge was redirected to, relative to the root.
    for name, node in nodes.items():
        if name == root:
            continue
        for edge_name, target in (node.get("inputs") or {}).items():
            if isinstance(target, str):
                if target in inputs:
                    inputs[target].followed_by.append(name)
            elif name in inputs:
                inputs[name].follows.append(f"{edge_name} -> {'.'.join(target)}")

    return sorted(inputs.values(), key=lambda item: item.name)


def build_report(inputs: Sequence[Input], stale_days: int) -> dict[str, Any]:
    now = int(datetime.datetime.now(tz=datetime.timezone.utc).timestamp())

    rows = [
        {
            "name": item.name,
            "reference": item.reference,
            "revision": (item.revision or "")[:12] or None,
            "ageDays": item.age_days(now),
            "follows": item.follows,
            "followedBy": sorted(set(item.followed_by)),
        }
        for item in inputs
    ]

    stale = [
        item.name
        for item in inputs
        if (age := item.age_days(now)) is not None and age >= stale_days
    ]

    return {
        "inputCount": len(rows),
        "staleThresholdDays": stale_days,
        "staleInputs": stale,
        "inputs": rows,
    }


def format_report(report: dict[str, Any], limit: int) -> str:
    stale_count = len(report["staleInputs"])
    threshold = report["staleThresholdDays"]
    lines = [
        f"inputs:  {report['inputCount']}",
        f"stale:   {stale_count} (at least {threshold} days old)",
        "",
    ]

    rows = report["inputs"] if limit <= 0 else report["inputs"][:limit]
    for row in rows:
        age = "unknown age" if row["ageDays"] is None else f"{row['ageDays']}d"
        marker = " *" if row["name"] in report["staleInputs"] else ""
        revision = row["revision"] or "?"
        lines.append(f"{row['name']}{marker}")
        lines.append(f"  {row['reference']}  {revision}  {age}")
        for edge in row["follows"]:
            lines.append(f"  follows {edge}")
        if row["followedBy"]:
            lines.append(f"  pinned by {', '.join(row['followedBy'])}")

    remaining = report["inputCount"] - len(rows)
    if remaining > 0:
        lines.append(f"... {remaining} more (raise --limit)")

    if report["staleInputs"]:
        lines.append("")
        lines.append("* stale. Age is the lock's lastModified, not a release date;")
        lines.append("  a pinned input is not automatically out of date.")

    return "\n".join(lines)


def parse_arguments(argv: Sequence[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("flake", nargs="?", default=".", help="flake reference")
    parser.add_argument(
        "--stale-days",
        type=int,
        default=90,
        help="age at which an input is flagged stale (default 90)",
    )
    parser.add_argument(
        "--limit",
        type=int,
        default=DEFAULT_LIMIT,
        help=f"cap listed inputs (default {DEFAULT_LIMIT}, 0 disables)",
    )
    parser.add_argument("--json", action="store_true", help="emit the report as JSON")
    return parser.parse_args(list(argv))


def main(argv: Sequence[str] | None = None) -> int:
    arguments = parse_arguments(sys.argv[1:] if argv is None else argv)

    try:
        metadata = read_metadata(arguments.flake)
    except FlakeInputError as error:
        print(f"error: {error}", file=sys.stderr)
        return 3

    report = build_report(collect_inputs(metadata), arguments.stale_days)

    if arguments.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        print(format_report(report, arguments.limit))

    return 0


if __name__ == "__main__":
    sys.exit(main())
