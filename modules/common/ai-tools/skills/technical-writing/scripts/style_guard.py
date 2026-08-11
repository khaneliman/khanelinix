#!/usr/bin/env python3
"""Check final output, commit messages, and technical-text rewrites."""

from __future__ import annotations

import argparse
import json
import re
import sys
from collections import Counter
from collections.abc import Iterable, Sequence
from pathlib import Path
from typing import Any

PROCEDURAL_WORD_LIMIT = 20
DESCRIPTIVE_WORD_LIMIT = 25
COMMIT_SUBJECT_LIMIT = 50
COMMIT_BODY_LINE_LIMIT = 72
COMMIT_BODY_CONTENT_LINES = 6
MAX_TRANSCRIPT_BYTES = 4 * 1024 * 1024

FORBIDDEN_PATTERNS = (
    ("phrase-01", re.compile(r"\bhonest(?:ly|y)?\b", re.IGNORECASE)),
    ("phrase-02", re.compile(r"\bload[- ]bearing\b", re.IGNORECASE)),
    (
        "phrase-03",
        re.compile(r"\bbelt[- ]and[- ]suspenders\b", re.IGNORECASE),
    ),
    ("phrase-04", re.compile(r"\bblast[- ]radius\b", re.IGNORECASE)),
    ("phrase-05", re.compile(r"\bdelv(?:e|es|ed|ing)\b", re.IGNORECASE)),
    ("phrase-06", re.compile(r"\btapestry\b", re.IGNORECASE)),
    ("phrase-07", re.compile(r"\bgame[- ]changer\b", re.IGNORECASE)),
    ("phrase-08", re.compile(r"\bparadigm shift\b", re.IGNORECASE)),
    ("phrase-09", re.compile(r"\bseamless(?:ly)?\b", re.IGNORECASE)),
    ("phrase-10", re.compile(r"\bever[- ]evolving\b", re.IGNORECASE)),
    (
        "phrase-11",
        re.compile(r"\bit(?:'s| is) (?:important|worth) to note\b", re.IGNORECASE),
    ),
    ("phrase-12", re.compile(r"\bat the end of the day\b", re.IGNORECASE)),
    (
        "phrase-13",
        re.compile(
            r"\bin today(?:'s|’s) (?:fast[- ]paced|rapidly evolving) world\b",
            re.IGNORECASE,
        ),
    ),
    ("phrase-14", re.compile(r"\ba testament to\b", re.IGNORECASE)),
    ("phrase-15", re.compile(r"\bunwavering commitment\b", re.IGNORECASE)),
    (
        "phrase-16",
        re.compile(r"\bunlock(?:s|ed|ing)? (?:the )?potential\b", re.IGNORECASE),
    ),
    (
        "phrase-17",
        re.compile(r"\bnavigat(?:e|es|ed|ing) the complexities\b", re.IGNORECASE),
    ),
    ("phrase-18", re.compile(r"\bgreat question\b", re.IGNORECASE)),
    (
        "phrase-19",
        re.compile(r"\bthat makes a lot of sense\b", re.IGNORECASE),
    ),
    ("phrase-20", re.compile(r"\babsolutely\b", re.IGNORECASE)),
    ("phrase-21", re.compile(r"\bdefinitely\b", re.IGNORECASE)),
)

# Generated from Unicode 17.0 Emoji_Presentation ranges. Explicit VS16 and
# keycap sequences also request emoji rendering and are blocked separately.
EMOJI_PRESENTATION_CLASS = (
    r"\u231a-\u231b\u23e9-\u23ec\u23f0\u23f3\u25fd-\u25fe"
    r"\u2614-\u2615\u2648-\u2653\u267f\u2693\u26a1"
    r"\u26aa-\u26ab\u26bd-\u26be\u26c4-\u26c5\u26ce\u26d4"
    r"\u26ea\u26f2-\u26f3\u26f5\u26fa\u26fd\u2705"
    r"\u270a-\u270b\u2728\u274c\u274e\u2753-\u2755\u2757"
    r"\u2795-\u2797\u27b0\u27bf\u2b1b-\u2b1c\u2b50\u2b55"
    r"\U0001f004\U0001f0cf\U0001f18e\U0001f191-\U0001f19a"
    r"\U0001f1e6-\U0001f1ff\U0001f201\U0001f21a\U0001f22f"
    r"\U0001f232-\U0001f236\U0001f238-\U0001f23a"
    r"\U0001f250-\U0001f251\U0001f300-\U0001f320"
    r"\U0001f32d-\U0001f335\U0001f337-\U0001f37c"
    r"\U0001f37e-\U0001f393\U0001f3a0-\U0001f3ca"
    r"\U0001f3cf-\U0001f3d3\U0001f3e0-\U0001f3f0\U0001f3f4"
    r"\U0001f3f8-\U0001f43e\U0001f440\U0001f442-\U0001f4fc"
    r"\U0001f4ff-\U0001f53d\U0001f54b-\U0001f54e"
    r"\U0001f550-\U0001f567\U0001f57a\U0001f595-\U0001f596"
    r"\U0001f5a4\U0001f5fb-\U0001f64f\U0001f680-\U0001f6c5"
    r"\U0001f6cc\U0001f6d0-\U0001f6d2\U0001f6d5-\U0001f6d8"
    r"\U0001f6dc-\U0001f6df\U0001f6eb-\U0001f6ec"
    r"\U0001f6f4-\U0001f6fc\U0001f7e0-\U0001f7eb\U0001f7f0"
    r"\U0001f90c-\U0001f93a\U0001f93c-\U0001f945"
    r"\U0001f947-\U0001f9ff\U0001fa70-\U0001fa7c"
    r"\U0001fa80-\U0001fa8a\U0001fa8e-\U0001fac6\U0001fac8"
    r"\U0001facd-\U0001fadc\U0001fadf-\U0001faea"
    r"\U0001faef-\U0001faf8"
)
EMOJI_RE = re.compile(rf"(?:[#*0-9]\ufe0f?\u20e3|.\ufe0f|[{EMOJI_PRESENTATION_CLASS}])")
WORD_RE = re.compile(r"[A-Za-z0-9]+(?:[-'][A-Za-z0-9]+)*")
SENTENCE_SPLIT_RE = re.compile(r"(?<=[.!?])(?:[\"')\]]*)\s+")
CONVENTIONAL_SUBJECT_RE = re.compile(
    r"^(?:feat|fix|refactor|docs|chore)\([^)]+\)!?: [a-z0-9]"
)
EXEMPT_SUBJECT_RE = re.compile(r'^(?:fixup! |squash! |amend! |Merge |Revert ")')
SCISSORS_RE = re.compile(
    r"^\s*# ------------------------ >8 ------------------------\s*$"
)
URL_RE = re.compile(r"https?://[^\s)>\]]+")
NUMBER_RE = re.compile(r"(?<![A-Za-z0-9_])[+-]?(?:\d+(?:[.,]\d+)*|\.\d+)")
INLINE_CODE_RE = re.compile(r"`([^`\n]+)`")
FENCED_CODE_RE = re.compile(
    r"^(?P<fence>`{3,}|~{3,})[^\n]*\n.*?^(?P=fence)[ \t]*$",
    re.DOTALL | re.MULTILINE,
)
TABLE_SEPARATOR_RE = re.compile(r"^\s*\|?(?:\s*:?-{3,}:?\s*\|)+\s*:?-{3,}:?\s*\|?\s*$")
TABLE_PIPE_RE = re.compile(r"(?<!\\)\|")
INLINE_CODE_PIPE_RE = re.compile(r"`[^`\n]*(?<!\\)\|[^`\n]*`")
TRAILER_RE = re.compile(
    r"^(?:Signed-off-by|Co-authored-by|Reviewed-by|Acked-by|Tested-by|"
    r"Reported-by|Suggested-by|Fixes|Refs):\s+\S",
    re.IGNORECASE,
)
STOPWORDS = {
    "a",
    "an",
    "and",
    "are",
    "as",
    "at",
    "be",
    "by",
    "for",
    "from",
    "in",
    "is",
    "it",
    "of",
    "on",
    "or",
    "that",
    "the",
    "this",
    "to",
    "was",
    "were",
    "with",
}


def line_column(text: str, offset: int) -> tuple[int, int]:
    line = text.count("\n", 0, offset) + 1
    last_newline = text.rfind("\n", 0, offset)
    return line, offset - last_newline


def style_violations(text: str) -> list[dict[str, int | str]]:
    matches: list[tuple[int, str, str]] = []
    for policy_id, pattern in FORBIDDEN_PATTERNS:
        matches.extend(
            (match.start(), "blocked-phrase", policy_id)
            for match in pattern.finditer(text)
        )
    matches.extend(
        (match.start(), "emoji", "emoji") for match in EMOJI_RE.finditer(text)
    )
    matches.extend(
        (match.start(), "unicode-dash", "dash") for match in re.finditer("\u2014", text)
    )

    violations = []
    for offset, kind, policy_id in sorted(matches):
        line, column = line_column(text, offset)
        violations.append(
            {
                "column": column,
                "kind": kind,
                "line": line,
                "policy_id": policy_id,
            }
        )
    return violations


def content_text(value: Any) -> str:
    if isinstance(value, str):
        return value
    if not isinstance(value, list):
        return ""
    parts = []
    for item in value:
        if not isinstance(item, dict) or item.get("type") in {
            "tool_use",
            "tool_result",
            "function_call",
            "custom_tool_call",
        }:
            continue
        text = item.get("text", item.get("content"))
        if isinstance(text, str):
            parts.append(text)
    return "\n".join(parts)


def transcript_path(payload: dict[str, Any]) -> Path | None:
    for name in ("transcript_path", "transcriptPath"):
        value = payload.get(name)
        if isinstance(value, str) and value:
            return Path(value).expanduser()
    return None


def read_transcript_tail(path: Path) -> list[dict[str, Any]]:
    try:
        with path.open("rb") as handle:
            size = path.stat().st_size
            start = max(0, size - MAX_TRANSCRIPT_BYTES)
            handle.seek(start)
            if start:
                handle.readline()
            raw_lines = handle.readlines()
    except OSError:
        return []

    records = []
    for raw_line in raw_lines:
        try:
            record = json.loads(raw_line)
        except (UnicodeDecodeError, json.JSONDecodeError):
            continue
        if isinstance(record, dict):
            records.append(record)
    return records


def read_transcript_head(path: Path, limit: int = 32) -> list[dict[str, Any]]:
    records = []
    try:
        with path.open(encoding="utf-8", errors="replace") as handle:
            for _, raw_line in zip(range(limit), handle):
                try:
                    record = json.loads(raw_line)
                except json.JSONDecodeError:
                    continue
                if isinstance(record, dict):
                    records.append(record)
    except OSError:
        pass
    return records


def is_subagent(payload: dict[str, Any], records: Iterable[dict[str, Any]]) -> bool:
    source = payload.get("source")
    if isinstance(source, dict) and "subagent" in source:
        return True
    for record in records:
        if record.get("type") != "session_meta":
            continue
        metadata = record.get("payload")
        if not isinstance(metadata, dict):
            continue
        source = metadata.get("source")
        return isinstance(source, dict) and "subagent" in source
    return False


def assistant_record_text(provider: str, record: dict[str, Any]) -> str:
    if provider == "claude" and record.get("type") == "assistant":
        if record.get("isSidechain") is True:
            return ""
        message = record.get("message")
        if isinstance(message, dict) and message.get("role") == "assistant":
            return content_text(message.get("content"))

    payload = record.get("payload")
    if provider == "codex" and isinstance(payload, dict):
        if (
            record.get("type") == "response_item"
            and payload.get("type") == "message"
            and payload.get("role") == "assistant"
        ):
            return content_text(payload.get("content"))
        if record.get("type") == "event_msg" and payload.get("type") == "agent_message":
            message = payload.get("message")
            return message if isinstance(message, str) else ""

    if provider == "antigravity" and record.get("type") in {
        "AGENT_RESPONSE",
        "ASSISTANT_RESPONSE",
        "MODEL_RESPONSE",
        "PLANNER_RESPONSE",
    }:
        return content_text(record.get("content"))
    return ""


def last_assistant_text(
    provider: str, payload: dict[str, Any], records: list[dict[str, Any]]
) -> str:
    for name in (
        "last_assistant_message",
        "lastAssistantMessage",
        "assistant_message",
        "assistantMessage",
    ):
        direct = content_text(payload.get(name))
        if direct:
            return direct
    latest = ""
    for record in records:
        text = assistant_record_text(provider, record)
        if text:
            latest = text
    return latest


def allow_hook(provider: str) -> None:
    print('{"decision":"stop"}' if provider == "antigravity" else "{}")


def block_hook(provider: str, violations: list[dict[str, int | str]]) -> None:
    locations = ", ".join(
        f"{item['policy_id']} at {item['line']}:{item['column']}"
        for item in violations[:12]
    )
    if len(violations) > 12:
        locations += f", plus {len(violations) - 12} more"
    reason = (
        "Final response violates output style policy. Remove each marker and "
        f"write the response again: {locations}."
    )
    decision = "continue" if provider == "antigravity" else "block"
    print(json.dumps({"decision": decision, "reason": reason}))


def command_hook(args: argparse.Namespace) -> int:
    try:
        payload = json.load(sys.stdin)
    except json.JSONDecodeError:
        payload = {}
    if not isinstance(payload, dict):
        payload = {}
    if payload.get("stop_hook_active") is True:
        allow_hook(args.provider)
        return 0
    path = transcript_path(payload)
    records = read_transcript_tail(path) if path is not None else []
    head_records = read_transcript_head(path) if path is not None else []
    if is_subagent(payload, (*head_records, *records)):
        allow_hook(args.provider)
        return 0
    text = last_assistant_text(args.provider, payload, records)
    violations = style_violations(text)
    if violations:
        block_hook(args.provider, violations)
    else:
        allow_hook(args.provider)
    return 0


def clean_commit_lines(text: str) -> list[str]:
    lines = [line.rstrip() for line in text.replace("\r\n", "\n").split("\n")]
    for index, line in enumerate(lines):
        if SCISSORS_RE.match(line):
            lines = lines[:index]
            break
    lines = [line for line in lines if not re.match(r"^\s*#", line)]
    while lines and not lines[-1]:
        lines.pop()
    return lines


def commit_errors(text: str) -> list[str]:
    lines = clean_commit_lines(text)
    if not lines:
        return ["commit message is empty"]
    subject = lines[0]
    if EXEMPT_SUBJECT_RE.match(subject):
        return []

    errors = []
    for violation in style_violations("\n".join(lines)):
        errors.append(
            f"line {violation['line']}: output policy {violation['policy_id']}"
        )
    if len(subject) > COMMIT_SUBJECT_LIMIT:
        errors.append(
            f"subject has {len(subject)} characters; limit is {COMMIT_SUBJECT_LIMIT}"
        )
    if not CONVENTIONAL_SUBJECT_RE.match(subject):
        errors.append("subject must use an approved scoped Conventional Commit form")
    if subject.endswith("."):
        errors.append("subject must not end with a period")
    if len(lines) < 3 or lines[1] != "" or not any(lines[2:]):
        errors.append("add a blank line and a commit body")
        return errors

    body = lines[2:]
    trailer_start = len(body)
    while trailer_start and TRAILER_RE.match(body[trailer_start - 1]):
        trailer_start -= 1
    body_lines = [
        (line_number, line)
        for line_number, line in enumerate(body[:trailer_start], start=3)
        if line
    ]
    if len(body_lines) > COMMIT_BODY_CONTENT_LINES:
        errors.append(
            f"body has {len(body_lines)} prose lines; limit is "
            f"{COMMIT_BODY_CONTENT_LINES}"
        )
    for line_number, line in body_lines:
        if len(line) > COMMIT_BODY_LINE_LIMIT:
            errors.append(
                f"line {line_number} has {len(line)} characters; limit is "
                f"{COMMIT_BODY_LINE_LIMIT}"
            )
    return errors


def command_commit_message(args: argparse.Namespace) -> int:
    try:
        text = args.path.read_text(encoding="utf-8")
    except OSError as exc:
        print(f"commit message read failed: {exc}", file=sys.stderr)
        return 2
    errors = commit_errors(text)
    if not errors:
        return 0
    for error in errors:
        print(f"commit message: {error}", file=sys.stderr)
    return 1


def command_scan(args: argparse.Namespace) -> int:
    paths = args.paths
    if not paths or (len(paths) == 1 and str(paths[0]) == "-"):
        violations = style_violations(sys.stdin.read())
    else:
        violations = []
        for path in paths:
            if str(path) == "-":
                print(
                    "input read failed: '-' cannot be combined with paths",
                    file=sys.stderr,
                )
                return 2
            try:
                text = path.read_text(encoding="utf-8")
            except OSError as exc:
                print(f"input read failed: {exc}", file=sys.stderr)
                return 2
            violations.extend(
                {"path": str(path), **violation} for violation in style_violations(text)
            )
    print(json.dumps({"passed": not violations, "violations": violations}, indent=2))
    return 1 if violations else 0


def markdown_sentences(text: str) -> list[str]:
    text = FENCED_CODE_RE.sub("", text)
    text = without_table_blocks(text)
    paragraphs: list[str] = []
    current: list[str] = []
    for raw_line in text.splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#"):
            if current:
                paragraphs.append(" ".join(current))
                current = []
            continue
        if re.match(r"^(?:[-*+] |\d+[.)] )", line):
            if current:
                paragraphs.append(" ".join(current))
                current = []
            paragraphs.append(re.sub(r"^(?:[-*+] |\d+[.)] )", "", line))
            continue
        current.append(line)
    if current:
        paragraphs.append(" ".join(current))
    sentences = []
    for paragraph in paragraphs:
        sentences.extend(
            part.strip() for part in SENTENCE_SPLIT_RE.split(paragraph) if part.strip()
        )
    return sentences


def table_blocks(text: str) -> list[str]:
    lines = text.splitlines()
    return ["\n".join(lines[start:end]) for start, end in table_spans(lines)]


def table_row_signature(line: str) -> tuple[bool, bool, int]:
    stripped = line.strip()
    return (
        stripped.startswith("|"),
        stripped.endswith("|"),
        len(TABLE_PIPE_RE.findall(line)),
    )


def table_spans(lines: Sequence[str]) -> list[tuple[int, int]]:
    spans = []
    index = 1
    while index < len(lines):
        if not TABLE_SEPARATOR_RE.match(lines[index]) or "|" not in lines[index - 1]:
            index += 1
            continue
        start = index - 1
        signature = table_row_signature(lines[start])
        end = index + 1
        while (
            end < len(lines)
            and table_row_signature(lines[end]) == signature
            and not INLINE_CODE_PIPE_RE.search(lines[end])
        ):
            end += 1
        spans.append((start, end))
        index = end
    return spans


def without_table_blocks(text: str) -> str:
    lines = text.splitlines()
    omitted = {
        line_number
        for start, end in table_spans(lines)
        for line_number in range(start, end)
    }
    output = [
        line for line_number, line in enumerate(lines) if line_number not in omitted
    ]
    return "\n".join(output)


def code_tokens(text: str) -> list[str]:
    fenced = [match.group(0) for match in FENCED_CODE_RE.finditer(text)]
    inline = INLINE_CODE_RE.findall(FENCED_CODE_RE.sub("", text))
    return fenced + inline


def counter_retention(source: Iterable[str], candidate: Iterable[str]) -> float:
    source_counts = Counter(source)
    if not source_counts:
        return 1.0
    candidate_counts = Counter(candidate)
    retained = sum(
        min(count, candidate_counts[item]) for item, count in source_counts.items()
    )
    return retained / sum(source_counts.values())


def lexical_tokens(text: str) -> list[str]:
    return [
        token
        for token in (match.group(0).lower() for match in WORD_RE.finditer(text))
        if token not in STOPWORDS
    ]


def score_rewrite(
    source: str,
    candidate: str,
    *,
    mode: str,
    minimum_retention: float,
    required_facts: Sequence[str],
) -> dict[str, Any]:
    word_limit = (
        PROCEDURAL_WORD_LIMIT if mode == "procedural" else DESCRIPTIVE_WORD_LIMIT
    )
    sentences = markdown_sentences(candidate)
    long_sentences = [
        {"text": sentence[:160], "words": len(WORD_RE.findall(sentence))}
        for sentence in sentences
        if len(WORD_RE.findall(sentence)) > word_limit
    ]
    source_tables = table_blocks(source)
    candidate_tables = table_blocks(candidate)
    missing_facts = [fact for fact in required_facts if fact not in candidate]
    metrics = {
        "blocked_output_markers": style_violations(candidate),
        "code_retention": counter_retention(
            code_tokens(source),
            code_tokens(candidate),
        ),
        "lexical_retention": counter_retention(
            lexical_tokens(source), lexical_tokens(candidate)
        ),
        "long_sentences": long_sentences,
        "missing_required_facts": missing_facts,
        "number_retention": counter_retention(
            NUMBER_RE.findall(source), NUMBER_RE.findall(candidate)
        ),
        "sentence_count": len(sentences),
        "tables_preserved": counter_retention(source_tables, candidate_tables),
        "url_retention": counter_retention(
            URL_RE.findall(source), URL_RE.findall(candidate)
        ),
        "word_limit": word_limit,
    }
    metrics["passed"] = bool(
        not metrics["blocked_output_markers"]
        and not long_sentences
        and not missing_facts
        and metrics["code_retention"] == 1.0
        and metrics["lexical_retention"] >= minimum_retention
        and metrics["number_retention"] == 1.0
        and metrics["tables_preserved"] == 1.0
        and metrics["url_retention"] == 1.0
    )
    metrics["minimum_lexical_retention"] = minimum_retention
    return metrics


def command_score(args: argparse.Namespace) -> int:
    try:
        source = args.source.read_text(encoding="utf-8")
        candidate = args.candidate.read_text(encoding="utf-8")
        required_facts = (
            [
                line
                for line in args.required_facts.read_text(encoding="utf-8").splitlines()
                if line
            ]
            if args.required_facts is not None
            else []
        )
    except OSError as exc:
        print(f"input read failed: {exc}", file=sys.stderr)
        return 2
    report = score_rewrite(
        source,
        candidate,
        mode=args.mode,
        minimum_retention=args.minimum_retention,
        required_facts=required_facts,
    )
    print(json.dumps(report, indent=2, sort_keys=True))
    return 0 if report["passed"] else 1


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)

    hook = subparsers.add_parser("hook", help="check a provider Stop payload")
    hook.add_argument("provider", choices=("claude", "codex", "antigravity"))
    hook.set_defaults(handler=command_hook)

    commit = subparsers.add_parser("commit-message", help="check a commit message")
    commit.add_argument("path", type=Path)
    commit.set_defaults(handler=command_commit_message)

    scan = subparsers.add_parser("scan", help="check text for blocked markers")
    scan.add_argument("paths", nargs="*", type=Path)
    scan.set_defaults(handler=command_scan)

    score = subparsers.add_parser("score", help="score a rewrite against its source")
    score.add_argument("source", type=Path)
    score.add_argument("candidate", type=Path)
    score.add_argument(
        "--mode", choices=("procedural", "descriptive"), default="descriptive"
    )
    score.add_argument("--minimum-retention", type=float, default=0.85)
    score.add_argument("--required-facts", type=Path)
    score.set_defaults(handler=command_score)
    return parser


def main(argv: Sequence[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    if hasattr(args, "minimum_retention") and not 0 <= args.minimum_retention <= 1:
        parser.error("--minimum-retention must be between 0 and 1")
    return args.handler(args)


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except BrokenPipeError:
        raise SystemExit(0) from None
