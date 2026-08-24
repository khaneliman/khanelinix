#!/usr/bin/env python3
"""Project portable skill invocation metadata into host frontmatter."""

from __future__ import annotations

import argparse
import json
import shutil
import stat
from pathlib import Path

INVOCATION_METADATA_KEY = "khanelinix-invocation-mode"
USER_ONLY_MODE = "user-only"
MODEL_INVOCATION_FIELD = "disable-model-invocation"
MODEL_HIDING_PROVIDERS = frozenset({"claude-code", "pi"})
SUPPORTED_PROVIDERS = frozenset({"claude-code", "codex", "pi"})


class ProjectionError(ValueError):
    """Report an invalid canonical manifest or projection request."""


def frontmatter_bounds(text: str) -> tuple[list[str], int]:
    lines = text.splitlines()
    if not lines or lines[0] != "---":
        raise ProjectionError("SKILL.md must start with YAML frontmatter")
    try:
        closing = lines.index("---", 1)
    except ValueError as error:
        raise ProjectionError("SKILL.md frontmatter is not closed") from error
    return lines, closing


def decode_metadata_string(raw: str) -> str:
    value = raw.strip()
    if value.startswith('"'):
        try:
            decoded = json.loads(value)
        except json.JSONDecodeError as error:
            raise ProjectionError(
                f"invalid {INVOCATION_METADATA_KEY} string"
            ) from error
        if not isinstance(decoded, str):
            raise ProjectionError(f"{INVOCATION_METADATA_KEY} must be a string")
        return decoded
    if value.startswith("'") and value.endswith("'"):
        return value[1:-1].replace("''", "'")
    return value


def invocation_mode(text: str) -> str | None:
    lines, closing = frontmatter_bounds(text)
    in_metadata = False
    mode: str | None = None
    for line in lines[1:closing]:
        if not line or line.lstrip().startswith("#"):
            continue
        if not line[0].isspace():
            key, separator, raw = line.partition(":")
            if not separator:
                raise ProjectionError(f"malformed top-level frontmatter: {line}")
            if key == MODEL_INVOCATION_FIELD:
                raise ProjectionError(
                    f"canonical skills must not declare {MODEL_INVOCATION_FIELD}"
                )
            in_metadata = key == "metadata"
            if in_metadata and raw.strip():
                raise ProjectionError("frontmatter metadata must be a mapping")
            continue
        if not in_metadata or not line.startswith("  ") or line.startswith("   "):
            continue
        key, separator, raw = line[2:].partition(":")
        if not separator or key != INVOCATION_METADATA_KEY:
            continue
        if mode is not None:
            raise ProjectionError(f"duplicate {INVOCATION_METADATA_KEY}")
        mode = decode_metadata_string(raw)

    if mode not in {None, USER_ONLY_MODE}:
        raise ProjectionError(
            f"unsupported {INVOCATION_METADATA_KEY}: {mode or '<empty>'}"
        )
    return mode


def project_manifest(text: str, provider: str) -> str:
    if provider not in SUPPORTED_PROVIDERS:
        raise ProjectionError(f"unsupported skill projection provider: {provider}")
    if (
        invocation_mode(text) != USER_ONLY_MODE
        or provider not in MODEL_HIDING_PROVIDERS
    ):
        return text

    lines = text.splitlines(keepends=True)
    closing = next(
        index
        for index, line in enumerate(lines[1:], start=1)
        if line.rstrip("\r\n") == "---"
    )
    newline = "\r\n" if lines[0].endswith("\r\n") else "\n"
    lines.insert(closing, f"{MODEL_INVOCATION_FIELD}: true{newline}")
    return "".join(lines)


def projected_directory_files(skill_dir: Path, provider: str) -> dict[str, bytes]:
    files: dict[str, bytes] = {}
    for path in sorted(skill_dir.rglob("*")):
        if not path.is_file() or "__pycache__" in path.parts or path.suffix == ".pyc":
            continue
        relative = path.relative_to(skill_dir).as_posix()
        if relative == "SKILL.md":
            files[relative] = project_manifest(
                path.read_text(encoding="utf-8"), provider
            ).encode()
        else:
            files[relative] = path.read_bytes()
    return files


def render_path(source: Path, destination: Path, provider: str) -> None:
    if not source.is_dir():
        raise ProjectionError(f"skill source is not a directory: {source}")
    if destination.exists():
        raise ProjectionError(
            f"skill projection destination already exists: {destination}"
        )

    shutil.copytree(
        source,
        destination,
        ignore=shutil.ignore_patterns("__pycache__", "*.pyc"),
    )
    if (source / "SKILL.md").is_file():
        manifests = [(source / "SKILL.md", destination / "SKILL.md")]
    else:
        manifests = [
            (child / "SKILL.md", destination / child.name / "SKILL.md")
            for child in sorted(source.iterdir())
            if child.is_dir() and (child / "SKILL.md").is_file()
        ]
    for source_manifest, destination_manifest in manifests:
        source_text = source_manifest.read_text(encoding="utf-8")
        projected = project_manifest(source_text, provider)
        if projected == source_text:
            continue
        destination_manifest.chmod(destination_manifest.stat().st_mode | stat.S_IWUSR)
        destination_manifest.write_text(projected, encoding="utf-8")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Render provider-specific invocation controls for agent skills."
    )
    parser.add_argument(
        "--provider", choices=sorted(SUPPORTED_PROVIDERS), required=True
    )
    parser.add_argument("source", type=Path)
    parser.add_argument("destination", type=Path)
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    try:
        render_path(args.source, args.destination, args.provider)
    except ProjectionError as error:
        raise SystemExit(f"skill projection error: {error}") from error


if __name__ == "__main__":
    main()
