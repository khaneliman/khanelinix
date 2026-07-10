#!/usr/bin/env python3
from __future__ import annotations

import json
import os
import subprocess
import tempfile
import unittest
from pathlib import Path

CODEX_DIR = Path(__file__).resolve().parent.parent
HOOK = CODEX_DIR / "hooks" / "okf_memory_context.py"


class ContextHookTests(unittest.TestCase):
    def run_hook(self, root: Path, event_name: str) -> subprocess.CompletedProcess[str]:
        payload = {
            "cwd": str(root),
            "hook_event_name": event_name,
            "session_id": "test-session",
        }
        env = os.environ.copy()
        env["PYTHONDONTWRITEBYTECODE"] = "1"
        return subprocess.run(
            ["python3", str(HOOK)],
            input=json.dumps(payload),
            cwd=root,
            env=env,
            text=True,
            capture_output=True,
            check=False,
        )

    def create_bundle(self, root: Path) -> None:
        bundle = root / ".okf"
        bundle.mkdir()
        (bundle / "index.md").write_text(
            '# Memory\n\nValue with "quotes" and newlines.\n', encoding="utf-8"
        )

    def assert_context_hook(
        self, result: subprocess.CompletedProcess[str], event_name: str
    ) -> None:
        self.assertEqual(result.returncode, 0, result.stderr)
        output = json.loads(result.stdout)
        hook_output = output["hookSpecificOutput"]
        self.assertEqual(hook_output["hookEventName"], event_name)
        self.assertIn("===BEGIN-OKF-MEMORY===", hook_output["additionalContext"])

    def test_session_start_emits_json_context(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            self.create_bundle(root)

            result = self.run_hook(root, "SessionStart")

            self.assert_context_hook(result, "SessionStart")

    def test_user_prompt_submit_emits_json_context(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            self.create_bundle(root)

            result = self.run_hook(root, "UserPromptSubmit")

            self.assert_context_hook(result, "UserPromptSubmit")

    def test_missing_bundle_emits_no_output(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            result = self.run_hook(Path(temp_dir), "UserPromptSubmit")

            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(result.stdout, "")


if __name__ == "__main__":
    unittest.main()
