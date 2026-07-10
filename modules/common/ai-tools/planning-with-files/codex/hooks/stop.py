#!/usr/bin/env python3
from __future__ import annotations

import json

import codex_hook_adapter as adapter


def main() -> None:
    payload = adapter.load_payload()
    root = adapter.cwd_from_payload(payload)

    if not adapter.is_session_attached(root, adapter.session_id_from_payload(payload)):
        return

    stdout, _ = adapter.run_shell_script("stop.sh", root, stdin=json.dumps(payload))
    result = adapter.parse_json(stdout)

    if result.get("decision") != "block":
        return

    reason = result.get("reason")
    if not isinstance(reason, str) or not reason:
        return

    adapter.emit_json({"decision": "block", "reason": reason})


if __name__ == "__main__":
    raise SystemExit(adapter.main_guard(main))
