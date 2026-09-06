"""Parse canonical skill invocation metadata."""

from __future__ import annotations

import json

INVOCATION_METADATA_KEY = "khanelinix-invocation-mode"
USER_ONLY_MODE = "user-only"
MODEL_INVOCATION_FIELD = "disable-model-invocation"


class MetadataError(ValueError):
    """Report invalid canonical skill metadata."""


def frontmatter_bounds(text: str) -> tuple[list[str], int]:
    lines = text.splitlines()
    if not lines or lines[0] != "---":
        raise MetadataError("SKILL.md must start with YAML frontmatter")
    try:
        closing = lines.index("---", 1)
    except ValueError as error:
        raise MetadataError("SKILL.md frontmatter is not closed") from error
    return lines, closing


def decode_metadata_string(raw: str) -> str:
    value = raw.strip()
    if value.startswith('"'):
        try:
            decoded = json.loads(value)
        except json.JSONDecodeError as error:
            raise MetadataError(f"invalid {INVOCATION_METADATA_KEY} string") from error
        if not isinstance(decoded, str):
            raise MetadataError(f"{INVOCATION_METADATA_KEY} must be a string")
        return decoded
    if value.startswith("'") and value.endswith("'"):
        return value[1:-1].replace("''", "'")
    return value


def invocation_mode(text: str) -> str | None:
    lines, closing = frontmatter_bounds(text)
    in_metadata = False
    mode: str | None = None
    native_mode = False
    for line in lines[1:closing]:
        if not line or line.lstrip().startswith("#"):
            continue
        if not line[0].isspace():
            key, separator, raw = line.partition(":")
            if not separator:
                raise MetadataError(f"malformed top-level frontmatter: {line}")
            if key == MODEL_INVOCATION_FIELD:
                if native_mode:
                    raise MetadataError(f"duplicate {MODEL_INVOCATION_FIELD}")
                if raw.strip() != "true":
                    raise MetadataError(f"{MODEL_INVOCATION_FIELD} must be true")
                native_mode = True
            in_metadata = key == "metadata"
            if in_metadata and raw.strip():
                raise MetadataError("frontmatter metadata must be a mapping")
            continue
        if not in_metadata or not line.startswith("  ") or line.startswith("   "):
            continue
        key, separator, raw = line[2:].partition(":")
        if not separator or key != INVOCATION_METADATA_KEY:
            continue
        if mode is not None:
            raise MetadataError(f"duplicate {INVOCATION_METADATA_KEY}")
        mode = decode_metadata_string(raw)

    if mode not in {None, USER_ONLY_MODE}:
        raise MetadataError(
            f"unsupported {INVOCATION_METADATA_KEY}: {mode or '<empty>'}"
        )
    if native_mode and mode != USER_ONLY_MODE:
        raise MetadataError(
            f"{MODEL_INVOCATION_FIELD} requires {INVOCATION_METADATA_KEY}: "
            f"{USER_ONLY_MODE}"
        )
    return mode
