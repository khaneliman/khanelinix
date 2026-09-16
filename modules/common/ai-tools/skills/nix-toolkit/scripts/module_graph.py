#!/usr/bin/env python3
"""Query a configuration's module graph: what was imported, and by what."""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from collections.abc import Iterator, Sequence
from dataclasses import dataclass
from typing import Any

DEFAULT_LIMIT = 40
STORE_PREFIX_PATTERN = re.compile(r"^/nix/store/[a-z0-9]{32}-[^/]*/")

# `graph` is a tree of { file, key, imports, disabled }, where `disabled` is a
# Boolean saying whether disabledModules excised this node.
GRAPH_EXPRESSION = """cfg:
  let
    strip = node: {
      inherit (node) file disabled;
      imports = map strip node.imports;
    };
  in map strip cfg.graph"""


class ModuleGraphError(RuntimeError):
    """Raised when the graph cannot be evaluated."""


@dataclass
class Node:
    file: str
    disabled: bool
    ancestors: tuple[str, ...]


def strip_store_prefix(path: str) -> str:
    return STORE_PREFIX_PATTERN.sub("", path)


def flatten(
    nodes: Sequence[dict[str, Any]], ancestors: tuple[str, ...] = ()
) -> Iterator[Node]:
    """Walk the import tree depth first, carrying each node's import chain."""
    for raw in nodes:
        file = strip_store_prefix(str(raw.get("file", "")))
        yield Node(
            file=file, disabled=bool(raw.get("disabled", False)), ancestors=ancestors
        )
        yield from flatten(raw.get("imports", []), ancestors + (file,))


def evaluate_graph(config_attr: str) -> list[dict[str, Any]]:
    command = ["nix", "eval", "--json", config_attr, "--apply", GRAPH_EXPRESSION]
    try:
        result = subprocess.run(
            command,
            check=False,
            capture_output=True,
            text=True,
            errors="surrogateescape",
        )
    except OSError as error:
        raise ModuleGraphError(f"could not run nix: {error}") from error

    _ = sys.stderr.write(result.stderr)
    if result.returncode != 0:
        raise ModuleGraphError(
            "evaluation failed; the configuration attribute may not exist"
        )

    return json.loads(result.stdout)


def build_report(
    nodes: Sequence[Node], pattern: str | None, show_disabled: bool
) -> dict[str, Any]:
    unique_files = {node.file for node in nodes}

    matches: list[Node] = list(nodes)
    if pattern is not None:
        expression = re.compile(pattern)
        matches = [node for node in nodes if expression.search(node.file)]
    if show_disabled:
        matches = [node for node in matches if node.disabled]

    return {
        "query": {"pattern": pattern, "disabledOnly": show_disabled},
        "totalNodes": len(nodes),
        "distinctFiles": len(unique_files),
        "matchCount": len(matches),
        "matches": [
            {
                "file": node.file,
                "disabled": node.disabled,
                "importedBy": list(node.ancestors[-3:]),
                "depth": len(node.ancestors),
            }
            for node in matches
        ],
    }


def format_report(report: dict[str, Any], limit: int) -> str:
    lines = [
        f"graph nodes:    {report['totalNodes']}",
        f"distinct files: {report['distinctFiles']}",
        f"matches:        {report['matchCount']}",
        "",
    ]

    if not report["matches"]:
        if report["query"]["disabledOnly"]:
            lines.append("No module in the graph was disabled.")
        elif report["query"]["pattern"] is None:
            lines.append("The graph is empty.")
        else:
            lines.append("No module in the graph matched.")
            lines.append("A file absent here was never imported, so its options")
            lines.append("are undeclared and its definitions never merge.")
        return "\n".join(lines)

    shown = report["matches"] if limit <= 0 else report["matches"][:limit]
    for match in shown:
        suffix = "  [disabled]" if match["disabled"] else ""
        lines.append(f"{match['file']}  (depth {match['depth']}){suffix}")
        for ancestor in match["importedBy"]:
            lines.append(f"  imported by {ancestor}")

    remaining = report["matchCount"] - len(shown)
    if remaining > 0:
        lines.append(f"... {remaining} more (raise --limit)")

    return "\n".join(lines)


def parse_arguments(argv: Sequence[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("config", help="flake attribute of an evaluated configuration")
    parser.add_argument(
        "pattern",
        nargs="?",
        help="regular expression matched against each module path",
    )
    parser.add_argument(
        "--disabled",
        action="store_true",
        help="only modules excised by disabledModules",
    )
    parser.add_argument(
        "--limit",
        type=int,
        default=DEFAULT_LIMIT,
        help=f"cap listed matches (default {DEFAULT_LIMIT}, 0 disables)",
    )
    parser.add_argument("--json", action="store_true", help="emit the report as JSON")
    return parser.parse_args(list(argv))


def main(argv: Sequence[str] | None = None) -> int:
    arguments = parse_arguments(sys.argv[1:] if argv is None else argv)

    if arguments.pattern is not None:
        try:
            re.compile(arguments.pattern)
        except re.error as error:
            print(f"error: invalid pattern: {error}", file=sys.stderr)
            return 2

    try:
        graph = evaluate_graph(arguments.config)
    except ModuleGraphError as error:
        print(f"error: {error}", file=sys.stderr)
        return 3

    nodes = list(flatten(graph))
    report = build_report(nodes, arguments.pattern, arguments.disabled)

    if arguments.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        print(format_report(report, arguments.limit))

    return 0 if report["matchCount"] else 1


if __name__ == "__main__":
    sys.exit(main())
