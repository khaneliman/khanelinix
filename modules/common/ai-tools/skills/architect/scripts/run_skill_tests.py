#!/usr/bin/env python3
"""Run every canonical skill unittest suite with bounded deterministic output."""

from __future__ import annotations

import argparse
import os
import re
import subprocess
import sys
from pathlib import Path
from typing import Sequence

TEST_COUNT_RE = re.compile(r"Ran (\d+) tests?")
MAX_FAILURE_LINES = 120


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "root",
        nargs="?",
        type=Path,
        default=Path(__file__).resolve().parents[2],
        help="canonical skills directory",
    )
    return parser


def discover_test_dirs(root: Path) -> list[Path]:
    test_files = list(root.glob("*/tests/test_*.py"))
    if root.name == "skills":
        test_files.extend(root.parent.glob("planning-with-files/*/tests/test_*.py"))
    return sorted(
        {test_file.parent.resolve() for test_file in test_files if test_file.is_file()},
        key=lambda path: path.as_posix(),
    )


def bounded_failure_output(output: str) -> str:
    lines = output.rstrip().splitlines()
    if len(lines) <= MAX_FAILURE_LINES:
        return "\n".join(lines)
    omitted = len(lines) - MAX_FAILURE_LINES
    return f"... {omitted} earlier lines omitted ...\n" + "\n".join(
        lines[-MAX_FAILURE_LINES:]
    )


def run_suite(root: Path, tests: Path) -> tuple[int, int, str]:
    env = os.environ.copy()
    env["PYTHONDONTWRITEBYTECODE"] = "1"
    result = subprocess.run(
        [
            sys.executable,
            "-B",
            "-m",
            "unittest",
            "discover",
            "-s",
            str(tests),
            "-p",
            "test_*.py",
        ],
        cwd=root,
        env=env,
        check=False,
        capture_output=True,
        text=True,
    )
    output = "\n".join(part for part in (result.stdout, result.stderr) if part)
    match = TEST_COUNT_RE.search(output)
    return result.returncode, int(match.group(1)) if match else 0, output


def suite_name(root: Path, tests: Path) -> str:
    try:
        relative = tests.relative_to(root)
    except ValueError:
        relative = tests.relative_to(root.parent)
    return "/".join(relative.parts[:-1])


def main(argv: Sequence[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    root = args.root.expanduser().resolve()
    if not root.is_dir():
        build_parser().error(f"skills root is not a directory: {root}")

    test_dirs = discover_test_dirs(root)
    if not test_dirs:
        print(f"No skill tests found under {root}", file=sys.stderr)
        return 2

    failures = 0
    total_tests = 0
    for tests in test_dirs:
        skill = suite_name(root, tests)
        returncode, count, output = run_suite(root, tests)
        total_tests += count
        if returncode == 0:
            print(f"PASS {skill}: {count} tests")
            continue
        failures += 1
        print(f"FAIL {skill}: {count} tests", file=sys.stderr)
        print(bounded_failure_output(output), file=sys.stderr)

    print(f"Skill suites: {len(test_dirs)}; tests: {total_tests}; failures: {failures}")
    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main())
