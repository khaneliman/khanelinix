"""Check public text for agent disclosure and prose-rule violations."""

from __future__ import annotations

import re
from pathlib import Path
from types import ModuleType

# Patterns are phrase-level so package names such as claude-code or
# CopilotChat-nvim pass.
DISCLOSURE_PATTERNS: tuple[tuple[str, re.Pattern[str]], ...] = (
    (
        "agent instruction file",
        re.compile(
            r"\b(?:AGENTS|CLAUDE|GEMINI|SKILL)\.md\b|(?<![\w/])\.(?:claude|codex)/"
        ),
    ),
    (
        "agent attribution",
        re.compile(
            r"^\s*(?:co-authored-by|assisted-by|generated-by)\s*:.*"
            r"\b(?:claude|anthropic|codex|openai|chatgpt|gpt|copilot|gemini|cursor|"
            r"aider|devin|llm|ai)\b|^\s*assisted-by\s*:|"
            r"\bgenerated\s+(?:with|by|using)\s+\[?(?:claude|codex|chatgpt|gpt|copilot|"
            r"gemini|cursor|an?\s+(?:ai|llm))",
            re.IGNORECASE | re.MULTILINE,
        ),
    ),
    (
        "agent process disclosure",
        re.compile(
            r"\b(?:tested|verified|checked|validated|reviewed|generated|written|"
            r"drafted|authored|produced|created|analy[sz]ed|investigated|found|"
            r"confirmed|assisted|helped|ran|run|done|made|fixed|built|implemented)"
            r"\s+(?:with|by|using|via|through)\s+(?:the\s+help\s+of\s+)?(?:an?\s+|my\s+|"
            r"our\s+)?(?:claude(?:\s+code)?|codex|chatgpt|gpt[-\s]?\d[\w.-]*|gemini|"
            r"copilot|opus|sonnet|haiku|ai|llms?|language\s+models?|coding\s+agents?|"
            r"sub-?agents?|ai\s+agents?|agents?(?!\s+forwarding))(?![\w-]|\.\w)|"
            r"\bas\s+an\s+ai\b|\bi(?:'m|\s+am)\s+an\s+ai\b|\bas\s+a\s+(?:large\s+)?"
            r"language\s+model\b",
            re.IGNORECASE,
        ),
    ),
    (
        "local helper script",
        re.compile(
            r"\b(?:review_draft|review_threads|pr_snapshot|inspect_pr_checks|"
            r"issue_scan|style_guard|authority_gate|skill_routing_hook|"
            r"okf_memory_hook)\.py\b"
        ),
    ),
)

_STYLE_GUARD: list[ModuleType | None] = []


def load_style_guard() -> ModuleType | None:
    if _STYLE_GUARD:
        return _STYLE_GUARD[0]
    _STYLE_GUARD.append(_import_style_guard())
    return _STYLE_GUARD[0]


def _import_style_guard() -> ModuleType | None:
    import importlib.util

    hooks = Path(__file__).resolve().parents[1]
    for candidate in (
        hooks / "style_guard.py",
        hooks.parents[1] / "skills/technical-writing/scripts/style_guard.py",
    ):
        if not candidate.is_file():
            continue
        spec = importlib.util.spec_from_file_location(
            "authority_style_guard", candidate
        )
        if spec is None or spec.loader is None:
            continue
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        return module
    return None


def without_quotes(text: str) -> str:
    return "\n".join(
        "" if line.lstrip().startswith(">") else line for line in text.split("\n")
    )


def disclosure_prose(text: str, guard: ModuleType | None) -> str:
    """Blank fenced blocks and quotes; inline code still names files and tools."""
    if guard is not None:
        text = guard.FENCED_CODE_RE.sub(
            lambda match: re.sub(r"[^\n]", " ", match.group(0)), text
        )
    return without_quotes(text.replace("`", ""))


def text_findings(
    texts: list[str], patterns: tuple[tuple[str, re.Pattern[str]], ...], style: bool
) -> list[str]:
    guard = load_style_guard()
    findings: list[str] = []
    for text in texts:
        prose = disclosure_prose(text, guard)
        for label, pattern in patterns:
            if match := pattern.search(prose):
                findings.append(f"{label} ({match.group(0).strip()[:60]!r})")
        if style and guard is not None:
            findings.extend(
                f"style {item['policy_id']}"
                for item in guard.style_violations(without_quotes(text))
            )
    return sorted(set(findings))


def fallback_texts(raw: str) -> list[str]:
    """Approximate unreadable bodies with command text minus paths and flags."""
    words = [
        word
        for word in re.split(r"\s+", raw)
        if "/" not in word and not word.startswith("-") and "=" not in word
    ]
    return [" ".join(words)]
