#!/usr/bin/env python3
"""Hold publishing, pushing, merging, and activation to the user's own request.

Agents run with approval prompts off, so standing "check with me first" rules
only hold when a hook checks them. The gate records what the latest genuine
user prompt asked for and denies gated commands the user did not request.
Everything it does not recognize passes through untouched.
"""

from __future__ import annotations

import json
import os
import shlex
import sys
from pathlib import Path
from typing import Any

from authority.classify import TRIGGER, analyze, fallback_actions
from authority.grants import (
    ACTIVATE,
    DISCLOSE,
    GRANTS_ENV,
    NEEDS,
    SETS_GRANTS,
    delegated_grants,
    environment_grants,
    expand_grants,
)
from authority.prompts import delegated_codex_session, is_notification, record_prompt
from authority.shell import Context
from authority.state import (
    locked_state,
    log_decision,
    read_state,
    state_path,
    state_root,
    write_state,
)
from authority.text import (
    ATTRIBUTION_ONLY,
    DISCLOSURE_PATTERNS,
    fallback_texts,
    text_findings,
)

PROVIDERS = {"claude", "codex"}
EVENTS = {"user-prompt", "pre-tool", "session-end"}
FILE_TOOLS = {"Write", "Edit", "MultiEdit", "apply_patch"}


def load_payload(stream: Any) -> dict[str, Any] | None:
    try:
        payload = json.load(stream)
    except (json.JSONDecodeError, OSError, TypeError, ValueError):
        return None
    return payload if isinstance(payload, dict) else None


def deny(reason: str) -> dict[str, Any]:
    return {
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": reason,
        }
    }


def written_text(tool_input: Any) -> str:
    if not isinstance(tool_input, dict):
        return ""
    parts = [tool_input.get(key) for key in ("content", "new_string", "command")]
    edits = tool_input.get("edits")
    if isinstance(edits, list):
        parts.extend(edit.get("new_string") for edit in edits if isinstance(edit, dict))
    return "\n".join(part for part in parts if isinstance(part, str))


def gate_delegation(
    provider: str, payload: dict[str, Any], root: Path, text: str
) -> dict[str, Any] | None:
    requested = delegated_grants(text)
    path = state_path(payload, root)
    if requested is None or path is None or payload.get("agent_id") is not None:
        log_decision(provider, payload, ["delegate grants"], "deny-delegate")
        return deny(
            f"Set {GRANTS_ENV} only to literal grant names the user gave this session, "
            "and only from the parent agent."
        )
    with locked_state(path):
        state = read_state(path)
        granted = expand_grants(state["turn"] | state["session"] | environment_grants())
        missing = expand_grants(requested) - granted
        if not missing:
            log_decision(provider, payload, ["delegate grants"], "allow-delegate")
            return None
        state["pending"] |= requested
        write_state(path, state)
    log_decision(provider, payload, ["delegate grants"], "deny-delegate")
    needs = ", ".join(NEEDS[key] for key in sorted(missing))
    return deny(
        f"Passing {GRANTS_ENV} to a launched job needs the user's go-ahead to {needs}. "
        'Ask the user first; a reply such as "yes" allows it.'
    )


def gate_tool(
    provider: str, payload: dict[str, Any], root: Path
) -> dict[str, Any] | None:
    tool_name = payload.get("tool_name")
    tool_input = payload.get("tool_input")
    if tool_name in FILE_TOOLS:
        text = written_text(tool_input)
        return (
            gate_delegation(provider, payload, root, text)
            if SETS_GRANTS.search(text)
            else None
        )
    if tool_name != "Bash":
        return None
    command = tool_input.get("command") if isinstance(tool_input, dict) else None
    if isinstance(command, list):
        command = " ".join(shlex.quote(str(part)) for part in command)
    if not isinstance(command, str) or not TRIGGER.search(command):
        return None
    if SETS_GRANTS.search(command):
        return gate_delegation(provider, payload, root, command)
    workdir = tool_input.get("workdir") if isinstance(tool_input, dict) else None
    cwd = Path(str(workdir or payload.get("cwd") or os.getcwd()))
    actions = analyze(command, Context(cwd, command, []))
    if not actions:
        return None
    labels = sorted({action.label for action in actions})

    if payload.get("agent_id") is not None:
        blocked = sorted(
            {
                a.label
                for a in actions
                if a.publishes or a.history or ACTIVATE in a.grants
            }
        )
        if blocked:
            log_decision(provider, payload, blocked, "deny-worker")
            return deny(
                f"Workers do not publish, push, activate, or change git history ({', '.join(blocked)}). "
                "Return the draft or diff to the parent instead."
            )

    commit_texts = [text for action in actions for text in action.commit_texts]
    attribution = text_findings(commit_texts, ATTRIBUTION_ONLY, style=False)
    if attribution:
        log_decision(provider, payload, labels, "deny-attribution")
        return deny(
            f"The commit message carries agent attribution: {'; '.join(attribution)}. "
            "Remove it; the user does not want agent trailers or footers in history."
        )

    required = set().union(*(action.grants for action in actions))
    if not required:
        return None
    path = state_path(payload, root)
    if path is None:
        if required <= expand_grants(environment_grants()):
            texts = [text for action in actions for text in action.public_texts]
            findings = text_findings(texts, DISCLOSURE_PATTERNS, style=True)
            if not findings:
                log_decision(provider, payload, labels, "allow")
                return None
        log_decision(provider, payload, labels, "deny-no-session")
        return deny(
            "The authority gate cannot identify this session, so it cannot confirm the user asked for this."
        )
    with locked_state(path):
        state = read_state(path)
        granted = expand_grants(state["turn"] | state["session"] | environment_grants())
        missing = required - granted
        public_texts = [text for action in actions for text in action.public_texts]
        if any(action.unresolved_text for action in actions):
            public_texts.extend(fallback_texts(command))
        findings = (
            []
            if DISCLOSE in granted
            else text_findings(public_texts, DISCLOSURE_PATTERNS, style=True)
        )
        if not missing and not findings:
            # A grant used this turn is spent and does not carry.
            if state["carry"] & required:
                state["carry"] -= required
                write_state(path, state)
            log_decision(provider, payload, labels, "allow")
            return None
        state["pending"] |= required | ({DISCLOSE} if findings else set())
        write_state(path, state)

    reasons: list[str] = []
    if missing:
        needs = ", ".join(NEEDS[key] for key in sorted(missing))
        reasons.append(
            f"`{', '.join(labels)}` needs the user's go-ahead to {needs}, and the user has not "
            "asked for that in this turn. Show them the exact target and text of this and "
            "every later gated step, ask in your reply, and end the turn; their next message "
            'is what allows them, and a plain "yes" works. A question tool answer does not '
            "count. Do not route around this check."
        )
        if provider == "codex" and delegated_codex_session(payload):
            reasons.append(
                "This session was launched by another agent, so its prompt grants nothing. "
                f"When the user asked for this, the launcher passes {GRANTS_ENV}, for "
                "example publish,push; report the denial instead of retrying."
            )
    if findings:
        reasons.append(
            f"The public text breaks the user's prose rules: {'; '.join(findings)}. Rewrite it "
            "without agent, model, or tooling references, emoji, or em dashes. If the user "
            "explicitly wants this wording, ask them first."
        )
    log_decision(provider, payload, labels, "deny-grant" if missing else "deny-text")
    return deny(" ".join(reasons))


def handle(
    provider: str, event: str, payload: dict[str, Any], root: Path
) -> dict[str, Any] | None:
    if provider not in PROVIDERS or event not in EVENTS:
        return None
    if event == "pre-tool":
        return gate_tool(provider, payload, root)
    path = state_path(payload, root)
    if path is None:
        return None
    if event == "session-end":
        with locked_state(path):
            write_state(path, {"turn": set(), "session": set(), "pending": set()})
        return None
    prompt = payload.get("prompt")
    if not isinstance(prompt, str) or is_notification(prompt):
        return None
    if provider == "codex" and delegated_codex_session(payload):
        return None
    with locked_state(path):
        write_state(path, record_prompt(provider, payload, read_state(path)))
    return None


def failure(
    event: str, payload: dict[str, Any], error: Exception
) -> dict[str, Any] | None:
    if event != "pre-tool":
        return None
    tool_input = payload.get("tool_input")
    command = tool_input.get("command") if isinstance(tool_input, dict) else None
    if isinstance(command, str) and fallback_actions(command):
        return deny(
            f"The authority gate failed ({error}); retry once, then tell the user if it persists."
        )
    return None


def main(argv: list[str] | None = None) -> int:
    args = argv if argv is not None else sys.argv[1:]
    if len(args) != 2:
        return 0
    payload = load_payload(sys.stdin)
    if payload is None:
        return 0
    try:
        output = handle(args[0], args[1], payload, state_root())
    except Exception as error:  # noqa: BLE001 - fail closed for recognizable writes
        output = failure(args[1], payload, error)
    if output is not None:
        json.dump(output, sys.stdout, ensure_ascii=False)
        sys.stdout.write("\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
