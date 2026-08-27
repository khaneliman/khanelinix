#!/usr/bin/env python3
"""Gate known Claude task shapes until their required skill is invoked."""

from __future__ import annotations

import contextlib
import fcntl
import json
import os
import re
import stat
import sys
import tempfile
import urllib.parse
from pathlib import Path
from typing import Any

PROVIDER = "claude"
EVENTS = {
    "user-prompt",
    "prompt-expansion",
    "pre-tool",
    "post-tool",
    "post-compact",
    "session-end",
}
GITHUB_URL = re.compile(r"""https?://github\.com/[^\s<>\[\]"'`]+""", re.IGNORECASE)
REVIEW_REQUEST = re.compile(r"\b(review|inspect|audit|check)\b", re.IGNORECASE)
NEGATED_REVIEW = re.compile(
    r"\b(?:do\s+not|don't|dont|never)\s+(?:\w+\s+){0,2}"
    r"(?:review|inspect|audit|check)\b",
    re.IGNORECASE,
)
PR_REVIEW_SKILL = "github-toolkit"
STATE_ERROR = "Skill-routing state is unavailable. Retry the prompt after fixing it."


def load_payload(stream: Any) -> dict[str, Any] | None:
    try:
        payload = json.load(stream)
    except (json.JSONDecodeError, OSError, TypeError, ValueError):
        return None
    return payload if isinstance(payload, dict) else None


def state_root() -> Path:
    runtime = os.environ.get("XDG_RUNTIME_DIR")
    if runtime:
        return Path(runtime) / "khanelinix-skill-routing"
    state_home = os.environ.get("XDG_STATE_HOME")
    base = Path(state_home) if state_home else Path.home() / ".local/state"
    return base / "khanelinix/skill-routing"


def state_path(payload: dict[str, Any], root: Path) -> Path | None:
    session_id = payload.get("session_id")
    if not isinstance(session_id, str) or not session_id:
        return None
    safe_id = re.sub(r"[^A-Za-z0-9_.-]", "_", session_id)
    return root / f"{safe_id}.json"


def required_skill(prompt: object) -> str | None:
    if not isinstance(prompt, str):
        return None
    urls = [match.group().rstrip(".,;:!?)") for match in GITHUB_URL.finditer(prompt)]
    has_pull_request = any(is_github_pull_request(url) for url in urls)
    request_text = GITHUB_URL.sub("", prompt)
    affirmative_text = NEGATED_REVIEW.sub("", request_text)
    if has_pull_request and REVIEW_REQUEST.search(affirmative_text):
        return PR_REVIEW_SKILL
    return None


def is_github_pull_request(url: str) -> bool:
    parsed = urllib.parse.urlsplit(url)
    if parsed.scheme not in {"http", "https"} or parsed.hostname != "github.com":
        return False
    segments = [segment for segment in parsed.path.split("/") if segment]
    return len(segments) >= 4 and segments[2] == "pull" and segments[3].isdigit()


def ensure_root(root: Path) -> None:
    root.mkdir(mode=0o700, parents=True, exist_ok=True)
    metadata = root.lstat()
    if stat.S_ISLNK(metadata.st_mode) or not stat.S_ISDIR(metadata.st_mode):
        raise OSError(f"skill-routing state root is not a directory: {root}")
    if metadata.st_uid != os.getuid():
        raise OSError(f"skill-routing state root is not owned by this user: {root}")
    root.chmod(0o700)


def read_state(path: Path) -> tuple[set[str], str | None]:
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError:
        return set(), None
    except (json.JSONDecodeError, OSError, TypeError) as error:
        raise OSError(f"invalid skill-routing state: {path}") from error
    if not isinstance(payload, dict):
        raise OSError(f"invalid skill-routing state: {path}")
    loaded_value = payload.get("loaded_skills", [])
    pending_value = payload.get("pending_skill")
    if not isinstance(loaded_value, list) or not all(
        isinstance(skill, str) and skill for skill in loaded_value
    ):
        raise OSError(f"invalid loaded skills in state: {path}")
    if pending_value is not None and not isinstance(pending_value, str):
        raise OSError(f"invalid pending skill in state: {path}")
    return set(loaded_value), pending_value


def write_state(path: Path, loaded: set[str], pending: str | None) -> None:
    if not loaded and pending is None:
        clear_state(path)
        return
    ensure_root(path.parent)
    descriptor, temporary = tempfile.mkstemp(prefix=".route-", dir=path.parent)
    try:
        with os.fdopen(descriptor, "w", encoding="utf-8") as handle:
            json.dump(
                {
                    "loaded_skills": sorted(loaded),
                    "pending_skill": pending,
                },
                handle,
            )
            handle.write("\n")
        os.chmod(temporary, 0o600)
        os.replace(temporary, path)
    finally:
        try:
            os.unlink(temporary)
        except FileNotFoundError:
            pass


@contextlib.contextmanager
def locked_state(path: Path):
    ensure_root(path.parent)
    lock_path = path.with_suffix(".lock")
    flags = os.O_CREAT | os.O_RDWR
    if hasattr(os, "O_NOFOLLOW"):
        flags |= os.O_NOFOLLOW
    descriptor = os.open(lock_path, flags, 0o600)
    try:
        metadata = os.fstat(descriptor)
        if not stat.S_ISREG(metadata.st_mode) or metadata.st_uid != os.getuid():
            raise OSError(f"invalid skill-routing lock: {lock_path}")
        os.fchmod(descriptor, 0o600)
        fcntl.flock(descriptor, fcntl.LOCK_EX)
        yield
    finally:
        os.close(descriptor)


def clear_state(path: Path) -> None:
    try:
        path.unlink()
    except FileNotFoundError:
        pass


def deny(reason: str) -> dict[str, Any]:
    return {
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": reason,
        }
    }


def state_failure(event: str, payload: dict[str, Any]) -> dict[str, Any] | None:
    if event == "user-prompt" and required_skill(payload.get("prompt")) is not None:
        return {"decision": "block", "reason": STATE_ERROR}
    if event == "pre-tool":
        return deny(STATE_ERROR)
    return None


def handle(
    provider: str,
    event: str,
    payload: dict[str, Any],
    root: Path,
) -> dict[str, Any] | None:
    if provider != PROVIDER or event not in EVENTS or not payload:
        return None
    if payload.get("agent_id") is not None:
        return None

    path = state_path(payload, root)
    if path is None:
        return None

    with locked_state(path):
        if event == "session-end":
            clear_state(path)
            return None

        loaded, pending = read_state(path)

        if event == "user-prompt":
            skill = required_skill(payload.get("prompt"))
            pending = skill if skill is not None and skill not in loaded else None
            write_state(path, loaded, pending)
            return None

        if event == "prompt-expansion":
            command = payload.get("command_name")
            if isinstance(command, str) and command:
                loaded.add(command)
                if pending == command:
                    pending = None
                write_state(path, loaded, pending)
            return None

        if event == "post-compact":
            write_state(path, set(), pending)
            return None

        tool_name = payload.get("tool_name")
        tool_input = payload.get("tool_input")
        invoked = tool_input.get("skill") if isinstance(tool_input, dict) else None

        if event == "post-tool" and tool_name == "Skill" and isinstance(invoked, str):
            loaded.add(invoked)
            if pending == invoked:
                pending = None
            write_state(path, loaded, pending)
            return None
        if event == "pre-tool" and pending is not None and tool_name != "Skill":
            return deny(
                f"Invoke the {pending} skill before task tools. This route owns the "
                "requested workflow."
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
    except OSError:
        output = state_failure(args[1], payload)
    if output is not None:
        json.dump(output, sys.stdout, ensure_ascii=False)
        sys.stdout.write("\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
