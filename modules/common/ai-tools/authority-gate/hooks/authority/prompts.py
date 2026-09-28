"""Record what each genuine user prompt grants."""

from __future__ import annotations

import json
import re
from pathlib import Path
from typing import Any

from .intent import (
    AFFIRMATIVE,
    AFFIRMATIVE_ONLY,
    DEFERRAL,
    KEEP_WORDING,
    NEGATIVE_REPLY,
    SCOPE_SPLIT,
    SESSION_SCOPE,
    intent,
    offer_text,
)
from .text import load_style_guard

NOTIFICATION = re.compile(
    r"^\s*(?:\[SYSTEM NOTIFICATION|<task-notification>|Stop hook feedback:)|"
    r"<task-notification>\s*<task-id>"
)


def is_notification(prompt: str) -> bool:
    return bool(NOTIFICATION.search(prompt[:400]))


def read_head_record(path: Path) -> dict[str, Any] | None:
    try:
        with path.open(encoding="utf-8", errors="replace") as handle:
            record = json.loads(handle.readline())
    except (OSError, json.JSONDecodeError):
        return None
    return record if isinstance(record, dict) else None


def delegated_codex_session(payload: dict[str, Any]) -> bool:
    """True when a parent agent, not a person, wrote this Codex prompt."""
    direct = payload.get("source")
    if isinstance(direct, dict) and "subagent" in direct:
        return True
    transcript = payload.get("transcript_path")
    if not isinstance(transcript, str) or not transcript:
        return False
    record = read_head_record(Path(transcript).expanduser())
    if record is None or record.get("type") != "session_meta":
        return False
    meta = record.get("payload")
    source = meta.get("source") if isinstance(meta, dict) else None
    return source == "exec" or (isinstance(source, dict) and "subagent" in source)


def last_assistant_message(provider: str, payload: dict[str, Any]) -> str:
    transcript = payload.get("transcript_path")
    guard = load_style_guard()
    if guard is None or not isinstance(transcript, str) or not transcript:
        return ""
    records = guard.read_transcript_tail(Path(transcript).expanduser())
    return guard.last_assistant_text(provider, {}, records)


def record_prompt(
    provider: str, payload: dict[str, Any], state: dict[str, set[str]]
) -> dict[str, set[str]]:
    prompt = payload["prompt"]
    granted, revoked = intent(prompt)
    if (
        AFFIRMATIVE.search(prompt)
        and not NEGATIVE_REPLY.search(prompt)
        and not DEFERRAL.search(prompt)
    ):
        message = last_assistant_message(provider, payload)
        confirms = AFFIRMATIVE_ONLY.match(prompt) is not None
        # A denial tells the agent to make its reply the ask, so a bare yes
        # covers every step that reply names, not only its offer sentences.
        asked = message if confirms and state["pending"] else offer_text(message)
        granted |= intent(asked, offer=True)[0]
        if confirms or KEEP_WORDING.search(prompt):
            granted |= state["pending"]
    granted -= revoked
    # Steering that neither declines nor revokes keeps the previous prompt's
    # unused grants for one more turn; a grant never carries twice.
    carried = set() if NEGATIVE_REPLY.search(prompt) else state["carry"] - revoked
    scoped: set[str] = set()
    for sentence in SCOPE_SPLIT.split(prompt):
        if SESSION_SCOPE.search(sentence):
            scoped |= intent(sentence)[0]
    session = (state["session"] - revoked) | (scoped - revoked)
    return {
        "turn": granted | carried,
        "session": session,
        "pending": set(),
        "carry": granted,
    }
