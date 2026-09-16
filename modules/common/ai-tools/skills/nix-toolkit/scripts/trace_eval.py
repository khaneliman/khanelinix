#!/usr/bin/env python3
"""Run a failing evaluation and distil its --show-trace output to the cause."""

from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
from collections.abc import Sequence
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

DEFAULT_FRAMES = 12
STORE_PREFIX_PATTERN = re.compile(r"^/nix/store/[a-z0-9]{32}-[^/]*/")
FRAME_PATTERN = re.compile(r"^\s*…\s+(?P<context>.*?)\s*$")
LOCATION_PATTERN = re.compile(r"^\s*at (?P<location>.*?):?\s*$")
ERROR_PATTERN = re.compile(r"^\s*error:\s*(?P<message>.*?)\s*$")
SOURCE_PATTERN = re.compile(r"^\s*\d+\|")
# Evaluator context that names a position rather than offering advice.
POSITIONAL_CONTEXT = re.compile(
    r"^(from call site|in the (left|right) operand of\b|in the condition\b)"
)
POSITION_SUFFIX = re.compile(r":\d+:\d+$")
# Nix renders flake-sourced frames as «flake-ref»/path. The pinned revision and
# narHash add length without helping a reader locate the file.
FLAKE_REFERENCE = re.compile(r"«([^»]*)»")
REVISION = re.compile(r"^[0-9a-f]{40}$")


class TraceEvalError(RuntimeError):
    """Raised when the evaluation cannot be run at all."""


@dataclass
class Frame:
    context: str
    location: str | None = None

    @property
    def is_call(self) -> bool:
        return self.context.startswith("while ")

    @property
    def is_hint(self) -> bool:
        """Advice the evaluator attached, as opposed to positional context."""
        return not self.is_call and not POSITIONAL_CONTEXT.match(self.context)


@dataclass
class Trace:
    errors: list[str] = field(default_factory=list)
    frames: list[Frame] = field(default_factory=list)
    source_lines: list[str] = field(default_factory=list)
    line_count: int = 0


def strip_store_prefix(path: str) -> str:
    return STORE_PREFIX_PATTERN.sub("", path)


def shorten_flake_reference(reference: str) -> str:
    reference = reference.split("?", 1)[0]
    parts = [
        part[:8] if REVISION.match(part) else part for part in reference.split("/")
    ]
    return "/".join(parts)


def shorten(path: str) -> str:
    """Make a frame path readable: drop store prefixes, abbreviate flake refs."""
    return FLAKE_REFERENCE.sub(
        lambda match: shorten_flake_reference(match.group(1)),
        strip_store_prefix(path),
    )


def parse_trace(text: str) -> Trace:
    trace = Trace()
    for line in text.splitlines():
        trace.line_count += 1

        error = ERROR_PATTERN.match(line)
        if error:
            message = error.group("message")
            if message:
                trace.errors.append(message)
            continue

        frame = FRAME_PATTERN.match(line)
        if frame:
            trace.frames.append(Frame(context=frame.group("context")))
            continue

        location = LOCATION_PATTERN.match(line)
        if (
            location
            and trace.frames
            and POSITION_SUFFIX.search(location.group("location"))
        ):
            trace.frames[-1].location = location.group("location")
            continue

        if SOURCE_PATTERN.match(line):
            trace.source_lines.append(line.strip())

    return trace


def is_project_frame(frame: Frame, root: Path) -> bool:
    """A frame is local when its file resolves to something under the root."""
    if frame.location is None:
        return False

    path = POSITION_SUFFIX.sub("", frame.location)
    relative = strip_store_prefix(path)

    # A store path counts only when the same relative path exists in the root,
    # which is how flake evaluation reports this project's own files.
    if relative != path:
        return (root / relative).exists()

    if os.path.isabs(path):
        return Path(path).is_relative_to(root) and Path(path).exists()

    return (root / path).exists()


def build_report(trace: Trace, root: Path, frames: int) -> dict[str, Any]:
    hints = list(dict.fromkeys(f.context for f in trace.frames if f.is_hint))
    call_frames = [frame for frame in trace.frames if frame.is_call]

    kept = call_frames if frames <= 0 else call_frames[-frames:]

    def render(frame: Frame) -> dict[str, str]:
        rendered: dict[str, str] = {"context": frame.context}
        if frame.location is not None:
            rendered["location"] = shorten(frame.location)
        return rendered

    return {
        "errors": trace.errors,
        "hints": hints,
        "traceLines": trace.line_count,
        "frameCount": len(call_frames),
        "innermostFrames": [render(frame) for frame in kept],
        "projectFrames": [
            render(frame) for frame in call_frames if is_project_frame(frame, root)
        ],
    }


def format_report(
    report: dict[str, Any], command: Sequence[str], full_path: str | None
) -> str:
    lines = [
        f"command:     {' '.join(command)}",
        f"trace lines: {report['traceLines']}",
    ]
    if full_path:
        lines.append(f"full trace:  {full_path}")
    lines.append("")

    for message in report["errors"]:
        lines.append(f"error: {message}")

    if report["hints"]:
        lines.append("")
        lines.append("evaluator hints:")
        lines.extend(f"  {hint}" for hint in report["hints"])

    if report["innermostFrames"]:
        lines.append("")
        lines.append(
            f"innermost frames ({len(report['innermostFrames'])}"
            f" of {report['frameCount']}, outermost first):"
        )
        for frame in report["innermostFrames"]:
            lines.append(f"  {frame['context']}")
            if "location" in frame:
                lines.append(f"    {frame['location']}")

    lines.append("")
    if report["projectFrames"]:
        lines.append("frames in this project:")
        for frame in report["projectFrames"]:
            lines.append(f"  {frame['context']}")
            if "location" in frame:
                lines.append(f"    {frame['location']}")
    else:
        lines.append("frames in this project: none")
        if report["frameCount"] == 0:
            lines.append("  The command failed before evaluating any project code.")
        else:
            lines.append("  The cause sits entirely inside dependencies. Re-run")
            lines.append("  against a narrower attribute, or widen with --frames 0.")

    return "\n".join(lines)


def run_command(command: Sequence[str]) -> subprocess.CompletedProcess[str]:
    try:
        return subprocess.run(
            list(command),
            check=False,
            capture_output=True,
            text=True,
            errors="surrogateescape",
        )
    except OSError as error:
        raise TraceEvalError(f"could not run {command[0]}: {error}") from error


def parse_arguments(argv: Sequence[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=__doc__,
        epilog=(
            "With no `--`, the command is `nix eval --show-trace "
            "--option eval-cache false <installable>`. After `--`, the command "
            "runs as given; add --show-trace yourself if it is not there."
        ),
    )
    parser.add_argument(
        "--frames",
        type=int,
        default=DEFAULT_FRAMES,
        help=f"innermost frames to keep (default {DEFAULT_FRAMES}, 0 keeps all)",
    )
    parser.add_argument(
        "--root",
        default=".",
        help="project root used to recognise project frames (default: .)",
    )
    parser.add_argument("--full", help="write the untruncated trace to this path")
    parser.add_argument("--json", action="store_true", help="emit the report as JSON")
    parser.add_argument(
        "installable",
        nargs="?",
        help="flake installable to evaluate, or omit and pass a command after --",
    )
    parser.add_argument("command", nargs=argparse.REMAINDER)
    return parser.parse_args(list(argv))


def resolve_command(arguments: argparse.Namespace) -> list[str]:
    remainder = list(arguments.command)
    if remainder and remainder[0] == "--":
        remainder = remainder[1:]

    # argparse consumes the first `--` itself, so the command's leading word
    # lands in `installable`. Trailing words therefore mean an explicit command.
    if remainder:
        leading = [arguments.installable] if arguments.installable else []
        return leading + remainder
    if arguments.installable:
        return [
            "nix",
            "eval",
            "--show-trace",
            "--option",
            "eval-cache",
            "false",
            arguments.installable,
        ]
    raise TraceEvalError("give an installable or a command after --")


def main(argv: Sequence[str] | None = None) -> int:
    arguments = parse_arguments(sys.argv[1:] if argv is None else argv)

    try:
        command = resolve_command(arguments)
    except TraceEvalError as error:
        print(f"error: {error}", file=sys.stderr)
        return 2

    root = Path(arguments.root)
    if not root.is_dir():
        print(f"error: --root is not a directory: {root}", file=sys.stderr)
        return 2
    root = root.resolve()

    try:
        result = run_command(command)
    except TraceEvalError as error:
        print(f"error: {error}", file=sys.stderr)
        return 2

    if result.returncode == 0:
        print("command succeeded; nothing to diagnose")
        return 0

    if arguments.full:
        Path(arguments.full).write_text(result.stderr, errors="surrogateescape")

    report = build_report(parse_trace(result.stderr), root, arguments.frames)

    if arguments.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        print(format_report(report, command, arguments.full))

    return 1


if __name__ == "__main__":
    sys.exit(main())
