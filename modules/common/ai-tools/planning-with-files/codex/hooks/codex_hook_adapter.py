#!/usr/bin/env python3
from __future__ import annotations

import json
import os
import re
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
    """Return True only when this session has a valid plan attachment."""
    if os.environ.get("PLANNING_DISABLED", "") == "1":
        return False  # issue #195: explicit per-invocation opt-out (one-shot exec/CI)
    return attached_plan_dir(root, session_id) is not None


def attached_plan_dir(root: Path, session_id: str | None) -> Path | None:
    """Resolve the plan pinned to a session, never the repository pointer."""
    if not session_id or not valid_identifier(session_id):
        return None
    sentinel = root / ".planning" / "sessions" / f"{session_id}.attached"
    try:
        plan_id = sentinel.read_text(encoding="utf-8").strip()
    except (OSError, UnicodeError):
        return None
    if plan_id == ".":
        candidate = root
    elif valid_identifier(plan_id):
        candidate = root / ".planning" / plan_id
    else:
        return None
    try:
        candidate = candidate.resolve(strict=True)
        root = root.resolve(strict=True)
        candidate.relative_to(root)
    except (OSError, RuntimeError, ValueError):
        return None
    return candidate if (candidate / "task_plan.md").is_file() else None


def valid_identifier(value: str) -> bool:
    return re.fullmatch(r"[A-Za-z0-9_][A-Za-z0-9._-]*", value) is not None


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
