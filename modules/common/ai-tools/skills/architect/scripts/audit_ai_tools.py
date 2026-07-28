#!/usr/bin/env python3
"""Audit skill structure without mutating the inspected tree."""

from __future__ import annotations

import argparse
import ast
import json
import re
import sys
from collections import defaultdict, deque
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Iterable, Sequence
from urllib.parse import unquote, urlsplit

RESOURCE_DIRS = ("references", "refs", "scripts", "assets")
IGNORED_PARTS = {".git", "__pycache__", "node_modules"}
INTERPRETER_SCRIPT_SUFFIXES = {
    ".bash",
    ".cjs",
    ".js",
    ".mjs",
    ".pl",
    ".ps1",
    ".py",
    ".rb",
    ".sh",
    ".ts",
}
SCRIPT_SUPPORT_NAMES = {"__init__.py", "requirements.txt"}
LINK_RE = re.compile(r"!?\[[^\]]*\]\(([^)]+)\)")
RESOURCE_MENTION_RE = re.compile(
    r"(?<![A-Za-z0-9_-])((?:references|refs|scripts|assets)/[A-Za-z0-9@_./+:-]+)"
)
TOP_LEVEL_YAML_RE = re.compile(r"^([A-Za-z0-9_-]+):(?:\s*(.*))?$")
FENCE_RE = re.compile(r"^\s*(`{3,}|~{3,})")
NON_STRING_YAML_SCALARS = {"false", "null", "true", "~"}
NUMBER_YAML_RE = re.compile(
    r"^[+-]?(?:0|[1-9][0-9_]*)(?:\.[0-9_]+)?(?:[eE][+-]?[0-9]+)?$"
)
BLOCK_SCALAR_RE = re.compile(
    r"^(?P<style>[|>])(?P<indicators>(?:[+-]?[1-9]?|[1-9][+-])?)$"
)
SKILL_NAME_RE = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")
MAX_SKILL_NAME_CHARACTERS = 64
MAX_SKILL_DESCRIPTION_CHARACTERS = 1024
SUPPORTED_FRONTMATTER_FIELDS = {"description", "license", "metadata", "name"}
OPENAI_REQUIRED_INTERFACE_FIELDS = {
    "default_prompt",
    "display_name",
    "short_description",
}


@dataclass(frozen=True)
class Finding:
    severity: str
    code: str
    path: str
    message: str
    line: int | None = None
    related: tuple[str, ...] = ()

    def to_dict(self) -> dict[str, object]:
        data = asdict(self)
        if self.line is None:
            data.pop("line")
        if not self.related:
            data.pop("related")
        return data


@dataclass(frozen=True)
class SkillRecord:
    path: str
    name: str | None
    line_count: int
    description_characters: int
    resources: int


@dataclass(frozen=True)
class MarkdownLink:
    target: str
    line: int


@dataclass(frozen=True)
class ProseBlock:
    path: Path
    line: int
    normalized: str


def display_path(path: Path, root: Path) -> str:
    try:
        return path.resolve().relative_to(root.resolve()).as_posix()
    except ValueError:
        return str(path.resolve())


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8", errors="replace")


def discover_skill_dirs(root: Path) -> list[Path]:
    if root.is_file() and root.name == "SKILL.md":
        return [root.parent.resolve()]
    if (root / "SKILL.md").is_file():
        return [root.resolve()]

    skill_dirs = {
        path.parent.resolve()
        for path in root.rglob("SKILL.md")
        if not IGNORED_PARTS.intersection(path.parts)
    }
    return sorted(skill_dirs, key=lambda path: path.as_posix())


def parse_string_scalar(key: str, raw: str) -> tuple[str | None, str | None]:
    value = raw.strip()
    if not value:
        return "", None
    if value[0] in "[{":
        return None, f"frontmatter {key} must be a string scalar, not a collection"
    if value[0] in "&*!":
        return None, f"frontmatter {key} uses unsupported YAML tag/anchor syntax"
    if value[0] == '"':
        try:
            decoded = json.loads(value)
        except json.JSONDecodeError:
            return None, f"frontmatter {key} has malformed double-quoted YAML"
        if not isinstance(decoded, str):
            return None, f"frontmatter {key} must be a string scalar"
        return decoded, None
    if value[0] == "'":
        if len(value) < 2 or value[-1] != "'":
            return None, f"frontmatter {key} has malformed single-quoted YAML"
        return value[1:-1].replace("''", "'"), None
    if value.casefold() in NON_STRING_YAML_SCALARS or NUMBER_YAML_RE.fullmatch(value):
        return None, f"frontmatter {key} must be a string scalar"
    if ": " in value:
        return None, f"frontmatter {key} has an unquoted mapping delimiter"
    return value, None


def fold_block_lines(lines: Sequence[str]) -> str:
    parts: list[str] = []
    index = 0
    while index < len(lines):
        line = lines[index]
        if not line:
            end = index
            while end < len(lines) and not lines[end]:
                end += 1
            previous_more_indented = bool(
                index > 0 and lines[index - 1] and lines[index - 1][0].isspace()
            )
            next_more_indented = bool(
                end < len(lines) and lines[end] and lines[end][0].isspace()
            )
            extra_break = int(previous_more_indented or next_more_indented)
            parts.append("\n" * (end - index + extra_break))
            index = end
            continue

        more_indented = line[0].isspace()
        parts.append(line)
        index += 1
        if index >= len(lines):
            continue

        next_line = lines[index]
        if not next_line:
            continue
        if more_indented or next_line[0].isspace():
            parts.append("\n")
        else:
            parts.append(" ")

    return "".join(parts)


def parse_block_scalar(
    key: str, header: str, lines: Sequence[str], start: int
) -> tuple[str | None, int, str | None]:
    header_without_comment = header.split(" #", maxsplit=1)[0].rstrip()
    match = BLOCK_SCALAR_RE.fullmatch(header_without_comment)
    if match is None:
        return None, start, f"frontmatter {key} has malformed block scalar header"

    content: list[str] = []
    index = start
    while index < len(lines):
        line = lines[index]
        if line and not line[0].isspace():
            break
        content.append(line)
        index += 1

    indicators = match.group("indicators")
    explicit_indent = next(
        (int(character) for character in indicators if character.isdigit()), None
    )
    indents: list[int] = []
    for line in content:
        if not line.strip():
            continue
        prefix = line[: len(line) - len(line.lstrip())]
        if "\t" in prefix:
            return None, index, f"frontmatter {key} block indentation uses a tab"
        indents.append(len(prefix))

    content_indent = explicit_indent
    if content_indent is None:
        content_indent = min(indents, default=0)

    normalized: list[str] = []
    for line in content:
        if not line.strip():
            normalized.append("")
            continue
        prefix = line[: len(line) - len(line.lstrip())]
        if len(prefix) < content_indent:
            return None, index, f"frontmatter {key} block has inconsistent indentation"
        normalized.append(line[content_indent:])

    trailing_empty = 0
    while normalized and not normalized[-1]:
        trailing_empty += 1
        normalized.pop()

    if match.group("style") == ">":
        value = fold_block_lines(normalized)
    else:
        value = "\n".join(normalized)

    if normalized:
        value += "\n" * (trailing_empty + 1)
    elif trailing_empty:
        value = "\n" * trailing_empty

    if "-" in indicators:
        value = value.rstrip("\n")
    elif "+" not in indicators:
        value = value.rstrip("\n")
        if value:
            value += "\n"
    return value, index, None


def parse_frontmatter(path: Path) -> tuple[dict[str, str], str | None]:
    lines = read_text(path).splitlines()
    if not lines or lines[0].strip() != "---":
        return {}, "missing opening YAML frontmatter boundary"

    closing = next(
        (index for index, line in enumerate(lines[1:], start=1) if line == "---"),
        None,
    )
    if closing is None:
        return {}, "missing closing YAML frontmatter boundary"

    values: dict[str, str] = {}
    frontmatter_lines = lines[1:closing]
    index = 0
    while index < len(frontmatter_lines):
        line = frontmatter_lines[index]
        if not line or line.lstrip().startswith("#"):
            index += 1
            continue
        if line[0].isspace():
            return {}, f"unexpected nested YAML at frontmatter line {index + 2}"
        match = TOP_LEVEL_YAML_RE.match(line)
        if not match:
            return {}, f"malformed top-level YAML at frontmatter line {index + 2}"
        key = match.group(1)
        value = (match.group(2) or "").strip()
        if key not in SUPPORTED_FRONTMATTER_FIELDS:
            return {}, f"unsupported frontmatter field: {key}"
        if key in {"name", "description"}:
            if key in values:
                return {}, f"duplicate frontmatter field: {key}"
            if value.startswith(("|", ">")):
                parsed, index, error = parse_block_scalar(
                    key, value, frontmatter_lines, index + 1
                )
            else:
                parsed, error = parse_string_scalar(key, value)
                index += 1
            if error is not None:
                return {}, error
            assert parsed is not None
            values[key] = parsed
        elif key == "license":
            parsed, error = parse_string_scalar(key, value)
            index += 1
            if error is not None:
                return {}, error
            assert parsed is not None
            values[key] = parsed
        else:
            if value:
                return {}, "frontmatter metadata must be an indented string mapping"
            index += 1
            metadata: dict[str, str] = {}
            while index < len(frontmatter_lines):
                nested = frontmatter_lines[index]
                if not nested or nested.lstrip().startswith("#"):
                    index += 1
                    continue
                if not nested[0].isspace():
                    break
                if not nested.startswith("  ") or nested.startswith("   "):
                    return {}, (
                        "frontmatter metadata must use exactly two-space indentation "
                        f"at line {index + 2}"
                    )
                nested_match = TOP_LEVEL_YAML_RE.match(nested[2:])
                if nested_match is None:
                    return (
                        {},
                        f"malformed metadata YAML at frontmatter line {index + 2}",
                    )
                metadata_key = nested_match.group(1)
                if metadata_key in metadata:
                    return {}, f"duplicate frontmatter metadata field: {metadata_key}"
                parsed, error = parse_string_scalar(
                    f"metadata.{metadata_key}", nested_match.group(2) or ""
                )
                if error is not None:
                    return {}, error
                assert parsed is not None
                metadata[metadata_key] = parsed
                index += 1
            values[key] = json.dumps(metadata, sort_keys=True)
    return values, None


def validate_openai_metadata(
    path: Path, skill_name: str | None, root: Path
) -> list[Finding]:
    findings: list[Finding] = []
    values: dict[str, str] = {}
    lines = read_text(path).splitlines()
    interface_index = next(
        (index for index, line in enumerate(lines) if line == "interface:"), None
    )
    metadata_path = display_path(path, root)
    if interface_index is None:
        return [
            Finding(
                "error",
                "invalid_openai_metadata",
                metadata_path,
                "agents/openai.yaml requires an interface mapping",
                1,
            )
        ]

    index = interface_index + 1
    while index < len(lines):
        line = lines[index]
        if not line or line.lstrip().startswith("#"):
            index += 1
            continue
        if not line[0].isspace():
            break
        if not line.startswith("  ") or line.startswith("   "):
            findings.append(
                Finding(
                    "error",
                    "invalid_openai_metadata",
                    metadata_path,
                    "interface fields must use exactly two-space indentation",
                    index + 1,
                )
            )
            return findings
        match = TOP_LEVEL_YAML_RE.match(line[2:])
        if match is None:
            findings.append(
                Finding(
                    "error",
                    "invalid_openai_metadata",
                    metadata_path,
                    "malformed interface field",
                    index + 1,
                )
            )
            return findings
        key = match.group(1)
        raw = (match.group(2) or "").strip()
        if key in values:
            findings.append(
                Finding(
                    "error",
                    "invalid_openai_metadata",
                    metadata_path,
                    f"duplicate interface field: {key}",
                    index + 1,
                )
            )
            return findings
        if not raw.startswith(('"', "'")):
            findings.append(
                Finding(
                    "error",
                    "invalid_openai_metadata",
                    metadata_path,
                    f"interface field {key} must use a quoted string",
                    index + 1,
                )
            )
            return findings
        parsed, error = parse_string_scalar(f"interface.{key}", raw)
        if error is not None:
            findings.append(
                Finding(
                    "error",
                    "invalid_openai_metadata",
                    metadata_path,
                    error,
                    index + 1,
                )
            )
            return findings
        assert parsed is not None
        values[key] = parsed
        index += 1

    missing = sorted(OPENAI_REQUIRED_INTERFACE_FIELDS - values.keys())
    if missing:
        findings.append(
            Finding(
                "error",
                "invalid_openai_metadata",
                metadata_path,
                "missing interface fields: " + ", ".join(missing),
                interface_index + 1,
            )
        )
        return findings

    short_description = values["short_description"]
    if not 25 <= len(short_description) <= 64:
        findings.append(
            Finding(
                "error",
                "invalid_openai_metadata",
                metadata_path,
                "short_description must contain 25-64 characters",
                interface_index + 1,
            )
        )
    if skill_name and f"${skill_name}" not in values["default_prompt"]:
        findings.append(
            Finding(
                "error",
                "invalid_openai_metadata",
                metadata_path,
                f"default_prompt must mention ${skill_name}",
                interface_index + 1,
            )
        )

    for key in ("icon_small", "icon_large"):
        target = values.get(key)
        if not target:
            continue
        resolved = (path.parent.parent / target).resolve()
        try:
            resolved.relative_to(path.parent.parent.resolve())
        except ValueError:
            exists = False
        else:
            exists = resolved.is_file()
        if not exists:
            findings.append(
                Finding(
                    "error",
                    "missing_openai_asset",
                    metadata_path,
                    f"{key} target does not exist: {target}",
                    interface_index + 1,
                )
            )
    return findings


def iter_markdown_links(content: str) -> Iterable[MarkdownLink]:
    fence: str | None = None
    for line_number, line in enumerate(content.splitlines(), start=1):
        fence_match = FENCE_RE.match(line)
        if fence_match:
            marker = fence_match.group(1)[0]
            if fence is None:
                fence = marker
            elif fence == marker:
                fence = None
            continue
        if fence is not None:
            continue
        for match in LINK_RE.finditer(line):
            raw = match.group(1).strip()
            if raw.startswith("<") and ">" in raw:
                target = raw[1 : raw.index(">")]
            else:
                target = raw.split(maxsplit=1)[0]
            yield MarkdownLink(target=target, line=line_number)


def resolve_local_link(source: Path, target: str) -> Path | None:
    if not target or target.startswith("#"):
        return None
    parsed = urlsplit(target)
    if parsed.scheme or parsed.netloc or target.startswith("/"):
        return None
    decoded = unquote(parsed.path)
    if not decoded:
        return None
    return (source.parent / decoded).resolve()


def markdown_links_to(source: Path, targets: set[Path]) -> bool:
    for link in iter_markdown_links(read_text(source)):
        resolved = resolve_local_link(source, link.target)
        if resolved is not None and resolved.resolve() in targets:
            return True
    return False


def markdown_files(skill_dir: Path) -> list[Path]:
    return sorted(
        (
            path
            for path in skill_dir.rglob("*.md")
            if path.is_file() and not IGNORED_PARTS.intersection(path.parts)
        ),
        key=lambda path: path.as_posix(),
    )


def resource_files(skill_dir: Path) -> list[Path]:
    resources: list[Path] = []
    for directory in RESOURCE_DIRS:
        base = skill_dir / directory
        if not base.is_dir():
            continue
        resources.extend(
            path
            for path in base.rglob("*")
            if path.is_file()
            and not IGNORED_PARTS.intersection(path.parts)
            and path.suffix != ".pyc"
        )
    return sorted(resources, key=lambda path: path.as_posix())


def mentions_static_dependency(content: str, relative: str, name: str) -> bool:
    if relative in content:
        return True
    pattern = re.compile(rf"(?<![A-Za-z0-9_.-]){re.escape(name)}(?![A-Za-z0-9_.-])")
    return pattern.search(content) is not None


def referenced_resources(skill_dir: Path) -> set[Path]:
    skill_file = skill_dir / "SKILL.md"
    reachable_markdown = {skill_file.resolve()}
    referenced: set[Path] = set()
    queue: deque[Path] = deque([skill_file])

    while queue:
        source = queue.popleft()
        if not source.is_file():
            continue
        content = read_text(source)
        for link in iter_markdown_links(content):
            resolved = resolve_local_link(source, link.target)
            if resolved is None:
                continue
            try:
                resolved.relative_to(skill_dir.resolve())
            except ValueError:
                continue
            if resolved.is_file():
                referenced.add(resolved)
                if (
                    resolved.suffix.lower() == ".md"
                    and resolved not in reachable_markdown
                ):
                    reachable_markdown.add(resolved)
                    queue.append(resolved)

        for match in RESOURCE_MENTION_RE.finditer(content):
            candidate = (skill_dir / match.group(1).rstrip(".,;:)]}>`'\"")).resolve()
            if candidate.is_file():
                referenced.add(candidate)
                if (
                    candidate.suffix.lower() == ".md"
                    and candidate not in reachable_markdown
                ):
                    reachable_markdown.add(candidate)
                    queue.append(candidate)

    metadata = skill_dir / "agents" / "openai.yaml"
    if metadata.is_file():
        content = read_text(metadata)
        for match in RESOURCE_MENTION_RE.finditer(content):
            candidate = (skill_dir / match.group(1).rstrip(".,;:)]}>`'\"")).resolve()
            if candidate.is_file():
                referenced.add(candidate)

    dependency_queue = deque(
        resource
        for resource in referenced
        if resource.parent.name == "scripts" or "scripts" in resource.parts
    )
    inspected_dependencies: set[Path] = set()
    all_resources = resource_files(skill_dir)
    while dependency_queue:
        source = dependency_queue.popleft()
        if source in inspected_dependencies or not source.is_file():
            continue
        inspected_dependencies.add(source)
        content = read_text(source)

        for candidate in all_resources:
            if candidate == source or candidate in referenced:
                continue
            relative = candidate.relative_to(skill_dir).as_posix()
            top_level = Path(relative).parts[0]
            if top_level not in {"assets", "scripts"}:
                continue
            if mentions_static_dependency(content, relative, candidate.name):
                referenced.add(candidate)
                if "scripts" in candidate.parts:
                    dependency_queue.append(candidate)

        if source.suffix.lower() != ".py":
            continue

        try:
            tree = ast.parse(content, filename=str(source))
        except SyntaxError:
            continue

        module_candidates: list[Path] = []
        for node in ast.walk(tree):
            if isinstance(node, ast.Import):
                module_candidates.extend(
                    source.parent.joinpath(*alias.name.split("."))
                    for alias in node.names
                )
            elif isinstance(node, ast.ImportFrom):
                base = source.parent
                for _ in range(max(node.level - 1, 0)):
                    base = base.parent
                if node.module:
                    module_candidates.append(base.joinpath(*node.module.split(".")))
                else:
                    module_candidates.extend(base / alias.name for alias in node.names)

        for module_path in module_candidates:
            candidates = (module_path.with_suffix(".py"), module_path / "__init__.py")
            for candidate in candidates:
                candidate = candidate.resolve()
                try:
                    candidate.relative_to(skill_dir.resolve())
                except ValueError:
                    continue
                if candidate.is_file() and candidate not in referenced:
                    referenced.add(candidate)
                    dependency_queue.append(candidate)
    return referenced


def is_script_support_file(relative: str, resource: Path) -> bool:
    parts = Path(relative).parts
    return (
        resource.name in SCRIPT_SUPPORT_NAMES
        or resource.name.endswith("_test.py")
        or (
            "templates" in parts
            and bool(resource.suffix)
            and resource.suffix.lower() not in INTERPRETER_SCRIPT_SUFFIXES
        )
    )


def is_invocable_script(resource: Path) -> bool:
    return not resource.suffix or resource.suffix.lower() in INTERPRETER_SCRIPT_SUFFIXES


def iter_prose_blocks(path: Path, minimum_characters: int) -> Iterable[ProseBlock]:
    lines = read_text(path).splitlines()
    index = 0
    if lines and lines[0].strip() == "---":
        index = next(
            (
                offset + 1
                for offset, line in enumerate(lines[1:], start=1)
                if line.strip() == "---"
            ),
            0,
        )

    fence: str | None = None
    block: list[str] = []
    block_line = index + 1

    def flush() -> ProseBlock | None:
        nonlocal block
        text = " ".join(part.strip() for part in block).strip()
        block = []
        normalized = re.sub(r"\s+", " ", text).casefold()
        if len(normalized) < minimum_characters or len(normalized.split()) < 12:
            return None
        return ProseBlock(path=path, line=block_line, normalized=normalized)

    for line_number, line in enumerate(lines[index:], start=index + 1):
        fence_match = FENCE_RE.match(line)
        if fence_match:
            result = flush()
            if result is not None:
                yield result
            marker = fence_match.group(1)[0]
            if fence is None:
                fence = marker
            elif fence == marker:
                fence = None
            continue
        if fence is not None:
            continue
        if not line.strip():
            result = flush()
            if result is not None:
                yield result
            block_line = line_number + 1
            continue
        if not block:
            block_line = line_number
        block.append(line)

    result = flush()
    if result is not None:
        yield result


def audit_skill(
    skill_dir: Path, root: Path, line_budget: int
) -> tuple[SkillRecord, list[Finding]]:
    findings: list[Finding] = []
    skill_file = skill_dir / "SKILL.md"
    skill_path = display_path(skill_file, root)
    content = read_text(skill_file)
    line_count = len(content.splitlines())
    frontmatter, frontmatter_error = parse_frontmatter(skill_file)
    name = frontmatter.get("name")
    description = frontmatter.get("description")

    if frontmatter_error:
        findings.append(
            Finding("error", "invalid_frontmatter", skill_path, frontmatter_error, 1)
        )
    else:
        if not name:
            findings.append(
                Finding(
                    "error",
                    "missing_name",
                    skill_path,
                    "frontmatter name is required",
                    1,
                )
            )
        elif len(name) > MAX_SKILL_NAME_CHARACTERS:
            findings.append(
                Finding(
                    "error",
                    "invalid_name",
                    skill_path,
                    f"frontmatter name {name!r} exceeds "
                    f"{MAX_SKILL_NAME_CHARACTERS} characters",
                    1,
                )
            )
        elif SKILL_NAME_RE.fullmatch(name) is None:
            findings.append(
                Finding(
                    "error",
                    "invalid_name",
                    skill_path,
                    f"frontmatter name {name!r} must use lowercase letters, digits, "
                    "and single internal hyphens",
                    1,
                )
            )
        elif name != skill_dir.name:
            findings.append(
                Finding(
                    "error",
                    "name_path_mismatch",
                    skill_path,
                    f"frontmatter name {name!r} does not match directory {skill_dir.name!r}",
                    1,
                )
            )
        if not description:
            findings.append(
                Finding(
                    "error",
                    "missing_description",
                    skill_path,
                    "frontmatter description is required",
                    1,
                )
            )
        elif len(description) > MAX_SKILL_DESCRIPTION_CHARACTERS:
            findings.append(
                Finding(
                    "error",
                    "description_too_long",
                    skill_path,
                    "frontmatter description exceeds "
                    f"{MAX_SKILL_DESCRIPTION_CHARACTERS} characters",
                    1,
                )
            )

    if line_count > line_budget:
        findings.append(
            Finding(
                "warning",
                "playbook_line_budget",
                skill_path,
                f"root playbook has {line_count} lines; target is {line_budget}",
            )
        )

    openai_metadata = skill_dir / "agents" / "openai.yaml"
    if openai_metadata.is_file():
        findings.extend(validate_openai_metadata(openai_metadata, name, root))

    for markdown in markdown_files(skill_dir):
        for link in iter_markdown_links(read_text(markdown)):
            resolved = resolve_local_link(markdown, link.target)
            if resolved is not None and not resolved.exists():
                findings.append(
                    Finding(
                        "error",
                        "broken_local_link",
                        display_path(markdown, root),
                        f"local link target does not exist: {link.target}",
                        link.line,
                    )
                )

    resources = resource_files(skill_dir)
    referenced = referenced_resources(skill_dir)
    for resource in resources:
        resource_path = display_path(resource, root)
        relative = resource.relative_to(skill_dir).as_posix()
        support_file = relative.startswith("scripts/") and is_script_support_file(
            relative, resource
        )
        if resource not in referenced and not support_file:
            code = (
                "script_uninvoked"
                if relative.startswith("scripts/") and is_invocable_script(resource)
                else "orphan_resource"
            )
            message = (
                "script is not routed or invoked from reachable skill guidance"
                if code == "script_uninvoked"
                else "resource is not reachable from skill guidance or metadata"
            )
            findings.append(Finding("warning", code, resource_path, message))

        try:
            shebang = resource.read_bytes()[:2] == b"#!"
        except OSError:
            shebang = False
        if (
            relative.startswith("scripts/")
            and shebang
            and not (resource.stat().st_mode & 0o111)
            and resource.suffix.lower() not in INTERPRETER_SCRIPT_SUFFIXES
        ):
            findings.append(
                Finding(
                    "warning",
                    "script_not_executable",
                    resource_path,
                    "script has a shebang but no executable mode bit",
                )
            )

    return (
        SkillRecord(
            path=display_path(skill_dir, root),
            name=name,
            line_count=line_count,
            description_characters=len(description or ""),
            resources=len(resources),
        ),
        findings,
    )


def audit_root(
    root: Path,
    *,
    line_budget: int = 100,
    minimum_duplicate_characters: int = 120,
) -> dict[str, object]:
    root = root.resolve()
    if not (root / "SKILL.md").is_file() and (root / "skills").is_dir():
        root = (root / "skills").resolve()
    skills = discover_skill_dirs(root) if root.exists() else []
    records: list[SkillRecord] = []
    findings: list[Finding] = []

    if not skills:
        findings.append(
            Finding(
                "error",
                "no_skills_found",
                display_path(root, root),
                "no SKILL.md files found",
            )
        )

    duplicate_blocks: dict[str, list[ProseBlock]] = defaultdict(list)
    block_skills: dict[Path, Path] = {}
    for skill_dir in skills:
        record, skill_findings = audit_skill(skill_dir, root, line_budget)
        records.append(record)
        findings.extend(skill_findings)
        for markdown in markdown_files(skill_dir):
            block_skills[markdown.resolve()] = skill_dir.resolve()
            for block in iter_prose_blocks(markdown, minimum_duplicate_characters):
                duplicate_blocks[block.normalized].append(block)

    for blocks in duplicate_blocks.values():
        unique_paths = {block.path.resolve() for block in blocks}
        if len(unique_paths) < 2:
            continue
        owning_skills = {block_skills[block.path.resolve()] for block in blocks}
        if len(owning_skills) == 1:
            skill_dir = next(iter(owning_skills))
            skill_file = (skill_dir / "SKILL.md").resolve()
            directly_coloaded = any(
                markdown_links_to(source, unique_paths - {source})
                for source in unique_paths
            )
            if skill_file not in unique_paths and not directly_coloaded:
                continue
        ordered = sorted(blocks, key=lambda block: (block.path.as_posix(), block.line))
        first = ordered[0]
        related = tuple(display_path(block.path, root) for block in ordered[1:])
        findings.append(
            Finding(
                "warning",
                "duplicate_block",
                display_path(first.path, root),
                "exact normalized prose block appears in multiple files",
                first.line,
                related,
            )
        )

    findings.sort(
        key=lambda finding: (
            0 if finding.severity == "error" else 1,
            finding.path,
            finding.line or 0,
            finding.code,
        )
    )
    errors = sum(finding.severity == "error" for finding in findings)
    warnings = len(findings) - errors
    description_characters = sum(record.description_characters for record in records)
    return {
        "root": str(root),
        "summary": {
            "skills": len(records),
            "errors": errors,
            "warnings": warnings,
            "description_characters": description_characters,
        },
        "skills": [asdict(record) for record in records],
        "findings": [finding.to_dict() for finding in findings],
    }


def render_markdown(report: dict[str, object]) -> str:
    summary = report["summary"]
    assert isinstance(summary, dict)
    lines = [
        "# AI Tools Audit",
        "",
        f"- Root: `{report['root']}`",
        f"- Skills: {summary['skills']}",
        f"- Errors: {summary['errors']}",
        f"- Warnings: {summary['warnings']}",
        f"- Description characters: {summary['description_characters']}",
        "",
    ]
    findings = report["findings"]
    assert isinstance(findings, list)
    if not findings:
        lines.append("No findings.")
        return "\n".join(lines) + "\n"

    lines.extend(
        [
            "| Severity | Code | Location | Message |",
            "| --- | --- | --- | --- |",
        ]
    )
    for finding in findings:
        assert isinstance(finding, dict)
        location = str(finding["path"])
        if "line" in finding:
            location += f":{finding['line']}"
        message = str(finding["message"])
        related = finding.get("related")
        if related:
            message += "; also: " + ", ".join(str(item) for item in related)
        escaped = [
            str(finding["severity"]),
            str(finding["code"]),
            location,
            message,
        ]
        escaped = [value.replace("|", "\\|").replace("\n", " ") for value in escaped]
        lines.append("| " + " | ".join(escaped) + " |")
    return "\n".join(lines) + "\n"


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Audit skill structure, resource routing, links, and exact duplicate prose."
    )
    parser.add_argument("root", nargs="?", default=".", help="skill or AI-tools root")
    parser.add_argument("--format", choices=("json", "markdown"), default="markdown")
    parser.add_argument(
        "--line-budget",
        type=int,
        default=100,
        help="root playbook line-count warning threshold",
    )
    parser.add_argument("--minimum-duplicate-characters", type=int, default=120)
    parser.add_argument(
        "--strict",
        action="store_true",
        help="return nonzero when warnings exist as well as errors",
    )
    return parser


def main(argv: Sequence[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    if args.line_budget < 1 or args.minimum_duplicate_characters < 1:
        build_parser().error("budgets must be positive integers")
    report = audit_root(
        Path(args.root),
        line_budget=args.line_budget,
        minimum_duplicate_characters=args.minimum_duplicate_characters,
    )
    if args.format == "json":
        json.dump(report, sys.stdout, indent=2, sort_keys=True)
        sys.stdout.write("\n")
    else:
        sys.stdout.write(render_markdown(report))

    summary = report["summary"]
    assert isinstance(summary, dict)
    has_errors = int(summary["errors"]) > 0
    has_warnings = int(summary["warnings"]) > 0
    return 1 if has_errors or (args.strict and has_warnings) else 0


if __name__ == "__main__":
    raise SystemExit(main())
