#!/usr/bin/env python3
from __future__ import annotations

import codex_hook_adapter as adapter


def main() -> None:
    payload = adapter.load_payload()
    root = adapter.cwd_from_payload(payload)
    session_id = adapter.session_id_from_payload(payload)

    if not adapter.is_session_attached(root, session_id):
        return

    stdout, _ = adapter.run_shell_script("session-start.sh", root, session_id)
    if stdout:
        adapter.emit_json(
            {
                "hookSpecificOutput": {
                    "hookEventName": "SessionStart",
                    "additionalContext": stdout,
                }
            }
        )


if __name__ == "__main__":
    raise SystemExit(adapter.main_guard(main))
