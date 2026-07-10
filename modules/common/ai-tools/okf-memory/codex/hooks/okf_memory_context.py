#!/usr/bin/env python3
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path
from typing import Any

HOOK_DIR = Path(__file__).resolve().parent
SCRIPT_BY_EVENT = {
    "SessionStart": "okf-memory-session-start.sh",
}


def load_payload() -> dict[str, Any]:
    try:
        payload = json.load(sys.stdin)
    except (json.JSONDecodeError, OSError):
        return {}
    return payload if isinstance(payload, dict) else {}


def main() -> None:
    payload = load_payload()
    event_name = payload.get("hook_event_name")
    script_name = SCRIPT_BY_EVENT.get(event_name)
    if not script_name:
        return

    cwd = payload.get("cwd")
    if not isinstance(cwd, str) or not cwd:
        cwd = str(Path.cwd())

    result = subprocess.run(
        ["sh", str(HOOK_DIR / script_name)],
        cwd=cwd,
        text=True,
        capture_output=True,
        check=False,
    )
    if result.stderr:
        print(result.stderr.rstrip(), file=sys.stderr)

    context = result.stdout.strip()
    if context:
        json.dump(
            {
                "hookSpecificOutput": {
                    "hookEventName": event_name,
                    "additionalContext": context,
                }
            },
            sys.stdout,
            ensure_ascii=False,
        )
        sys.stdout.write("\n")


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:  # pragma: no cover
        print(f"[okf-memory hook] {exc}", file=sys.stderr)
