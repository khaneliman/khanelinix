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


def parse_frontmatter(path: Path) -> tuple[dict[str, str], str | None]:
    lines = read_text(path).splitlines()
    if not lines or lines[0].strip() != "---":
        return {}, "missing opening YAML frontmatter boundary"

    closing = next(
        (
            index
            for index, line in enumerate(lines[1:], start=1)
            if line.strip() == "---"
        ),
        None,
    )
    if closing is None:
        return {}, "missing closing YAML frontmatter boundary"

    values: dict[str, str] = {}
    frontmatter_lines = lines[1:closing]
    for index, line in enumerate(frontmatter_lines):
        if not line or line[0].isspace() or line.lstrip().startswith("#"):
            continue
        match = TOP_LEVEL_YAML_RE.match(line)
        if not match:
            return {}, f"malformed top-level YAML at frontmatter line {index + 2}"
        key = match.group(1)
        value = (match.group(2) or "").strip()
        if key in {"name", "description"}:
            if key in values:
                return {}, f"duplicate frontmatter field: {key}"
            parsed, error = parse_string_scalar(key, value)
            if error is not None:
                return {}, error
            assert parsed is not None
            values[key] = parsed
        else:
            values[key] = value
    return values, None


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

    python_queue = deque(
        resource for resource in referenced if resource.suffix.lower() == ".py"
    )
    inspected_python: set[Path] = set()
    while python_queue:
        source = python_queue.popleft()
        if source in inspected_python:
            continue
        inspected_python.add(source)
        try:
            tree = ast.parse(read_text(source), filename=str(source))
        except SyntaxError:
            continue

        module_names: list[str] = []
        for node in ast.walk(tree):
            if isinstance(node, ast.Import):
                module_names.extend(alias.name for alias in node.names)
            elif isinstance(node, ast.ImportFrom) and node.level == 0 and node.module:
                module_names.append(node.module)

        for module_name in module_names:
            module_path = source.parent.joinpath(*module_name.split("."))
            candidates = (module_path.with_suffix(".py"), module_path / "__init__.py")
            for candidate in candidates:
                candidate = candidate.resolve()
                try:
                    candidate.relative_to(skill_dir.resolve())
                except ValueError:
                    continue
                if candidate.is_file() and candidate not in referenced:
                    referenced.add(candidate)
                    python_queue.append(candidate)
    return referenced


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
        if not frontmatter.get("description"):
            findings.append(
                Finding(
                    "error",
                    "missing_description",
                    skill_path,
                    "frontmatter description is required",
                    1,
                )
            )

    if line_count > line_budget:
        findings.append(
            Finding(
                "error",
                "playbook_line_budget",
                skill_path,
                f"root playbook has {line_count} lines; budget is {line_budget}",
            )
        )

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
        if resource not in referenced:
            code = (
                "script_uninvoked"
                if relative.startswith("scripts/")
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
    for skill_dir in skills:
        record, skill_findings = audit_skill(skill_dir, root, line_budget)
        records.append(record)
        findings.extend(skill_findings)
        for markdown in markdown_files(skill_dir):
            for block in iter_prose_blocks(markdown, minimum_duplicate_characters):
                duplicate_blocks[block.normalized].append(block)

    for blocks in duplicate_blocks.values():
        unique_paths = {block.path.resolve() for block in blocks}
        if len(unique_paths) < 2:
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
    return {
        "root": str(root),
        "summary": {
            "skills": len(records),
            "errors": errors,
            "warnings": warnings,
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
    parser.add_argument("--line-budget", type=int, default=100)
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
