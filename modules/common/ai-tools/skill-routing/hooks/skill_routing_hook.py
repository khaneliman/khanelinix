#!/usr/bin/env python3
"""Suggest a known review workflow without gating tools or persisting state."""

from __future__ import annotations

import json
import re
import sys
import urllib.parse
from typing import Any

PROVIDER = "claude"
GITHUB_URL = re.compile(r"""https?://github\.com/[^\s<>\[\]"'`]+""", re.IGNORECASE)
REVIEW_REQUEST = re.compile(r"\b(review|inspect|audit)\b", re.IGNORECASE)
NEGATED_REVIEW = re.compile(
    r"\b(?:do\s+not|don't|dont|never)\s+(?:\w+\s+){0,2}"
    r"(?:review|inspect|audit|check)\b",
    re.IGNORECASE,
)
PR_REVIEW_SKILL = "github-toolkit"
# Background task results reach UserPromptSubmit too; their text is worker
# output, not a request.
NOTIFICATION = re.compile(
    r"^\s*(?:\[SYSTEM NOTIFICATION|<task-notification>|Stop hook feedback:)|"
    r"<task-notification>\s*<task-id>"
)


def load_payload(stream: Any) -> dict[str, Any] | None:
    try:
        payload = json.load(stream)
    except (json.JSONDecodeError, OSError, TypeError, ValueError):
        return None
    return payload if isinstance(payload, dict) else None


def suggested_skill(prompt: object) -> str | None:
    if not isinstance(prompt, str):
        return None
    urls = [match.group().rstrip(".,;:!?)") for match in GITHUB_URL.finditer(prompt)]
    has_pull_request = any(is_github_pull_request(url) for url in urls)
    request_text = GITHUB_URL.sub("", prompt)
    if NEGATED_REVIEW.search(request_text):
        return None
    if has_pull_request and REVIEW_REQUEST.search(request_text):
        return PR_REVIEW_SKILL
    return None


def is_github_pull_request(url: str) -> bool:
    parsed = urllib.parse.urlsplit(url)
    if parsed.scheme not in {"http", "https"} or parsed.hostname != "github.com":
        return False
    segments = [segment for segment in parsed.path.split("/") if segment]
    return len(segments) >= 4 and segments[2] == "pull" and segments[3].isdigit()


def handle(provider: str, event: str, payload: dict[str, Any]) -> dict[str, Any] | None:
    if provider != PROVIDER or event != "user-prompt" or not payload:
        return None
    if payload.get("agent_id") is not None:
        return None
    prompt = payload.get("prompt")
    if not isinstance(prompt, str) or NOTIFICATION.search(prompt[:400]):
        return None
    skill = suggested_skill(prompt)
    if skill is None:
        return None
    return {
        "hookSpecificOutput": {
            "hookEventName": "UserPromptSubmit",
            "additionalContext": (
                f"For this PR review, use {skill}'s shared premise-first review "
                "process and follow the user's stated scope. For another "
                "contributor's PR, the normal delivery is a pending review for "
                "the user to inspect, never a submitted review. This reminder "
                "does not gate tools or expand authorization."
            ),
        }
    }


def main(argv: list[str] | None = None) -> int:
    args = argv if argv is not None else sys.argv[1:]
    if len(args) != 2:
        return 0
    payload = load_payload(sys.stdin)
    if payload is None:
        return 0
    output = handle(args[0], args[1], payload)
    if output is not None:
        json.dump(output, sys.stdout, ensure_ascii=False)
        sys.stdout.write("\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
