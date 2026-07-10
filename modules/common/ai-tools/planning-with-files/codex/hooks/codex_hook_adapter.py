#!/usr/bin/env python3
from __future__ import annotations

import json
import os
import subprocess
import sys
from pathlib import Path
from typing import Any

HOOK_DIR = Path(__file__).resolve().parent


def load_payload() -> dict[str, Any]:
    raw = sys.stdin.read().strip()
    if not raw:
        return {}
    try:
        payload = json.loads(raw)
    except json.JSONDecodeError:
        return {}
    return payload if isinstance(payload, dict) else {}


def cwd_from_payload(payload: dict[str, Any]) -> Path:
    cwd = payload.get("cwd")
    if isinstance(cwd, str) and cwd:
        return Path(cwd)
    return Path.cwd()


def session_id_from_payload(payload: dict[str, Any]) -> str | None:
    sid = payload.get("session_id")
    if isinstance(sid, str) and sid:
        return sid
    env_sid = os.environ.get("PWF_SESSION_ID", "")
    return env_sid if env_sid else None


def is_session_attached(root: Path, session_id: str | None) -> bool:
    """Return True if this session should receive plan context.

    Legacy mode: if .planning/sessions/ does not exist, always return True so
    existing single-session users are not broken on upgrade.
    Isolation mode: return True only when the session has an attached sentinel.
    """
    if os.environ.get("PLANNING_DISABLED", "") == "1":
        return False  # issue #195: explicit per-invocation opt-out (one-shot exec/CI)
    sessions_dir = root / ".planning" / "sessions"
    if not sessions_dir.exists():
        return True  # legacy — no sessions dir means single-session setup
    if not session_id:
        return False  # sessions dir exists but caller has no ID — stay silent
    return (sessions_dir / f"{session_id}.attached").exists()


def emit_json(payload: dict[str, Any]) -> None:
    if not payload:
        return
    json.dump(payload, sys.stdout, ensure_ascii=False)
    sys.stdout.write("\n")


def parse_json(text: str) -> dict[str, Any]:
    if not text.strip():
        return {}
    try:
        payload = json.loads(text)
    except json.JSONDecodeError:
        return {}
    return payload if isinstance(payload, dict) else {}


def run_shell_script(
    script_name: str,
    cwd: Path,
    session_id: str | None = None,
    stdin: str | None = None,
) -> tuple[str, str]:
    env = os.environ.copy()
    if session_id:
        env["PWF_SESSION_ID"] = session_id

    result = subprocess.run(
        ["sh", str(HOOK_DIR / script_name)],
        cwd=str(cwd),
        env=env,
        input=stdin,
        text=True,
        capture_output=True,
        check=False,
    )
    return result.stdout.strip(), result.stderr.strip()


def main_guard(func) -> int:
    try:
        func()
    except Exception as exc:  # pragma: no cover
        print(f"[planning-with-files hook] {exc}", file=sys.stderr)
        return 0
    return 0
