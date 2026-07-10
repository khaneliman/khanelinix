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
    source = payload.get("source")
    if source in {"clear", "compact"}:
        nudge, _ = adapter.run_shell_script("user-prompt-submit.sh", root, session_id)
        stdout = "\n".join(part for part in (stdout, nudge) if part)
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
