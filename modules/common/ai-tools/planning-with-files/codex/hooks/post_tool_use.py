#!/usr/bin/env python3
from __future__ import annotations

import codex_hook_adapter as adapter


def main() -> None:
    payload = adapter.load_payload()
    root = adapter.cwd_from_payload(payload)

    if not adapter.is_session_attached(root, adapter.session_id_from_payload(payload)):
        return

    stdout, _ = adapter.run_shell_script("post-tool-use.sh", root)
    if stdout:
        adapter.emit_json({"systemMessage": stdout})


if __name__ == "__main__":
    raise SystemExit(adapter.main_guard(main))
