#!/usr/bin/env python3
from __future__ import annotations

import json
import os
import subprocess
import tempfile
import unittest
from pathlib import Path

CODEX_DIR = Path(__file__).resolve().parent.parent
HOOK_DIR = CODEX_DIR / "hooks"


class ContextHookTests(unittest.TestCase):
    def run_hook(
        self, script: str, root: Path, event: str, session_id: str = "test-session"
    ) -> subprocess.CompletedProcess[str]:
        payload = {
            "cwd": str(root),
            "hook_event_name": event,
            "session_id": session_id,
        }
        env = os.environ.copy()
        env["CODEX_SESSIONS_DIR"] = str(root / "codex-sessions")
        env["PYTHONDONTWRITEBYTECODE"] = "1"
        return subprocess.run(
            ["python3", str(HOOK_DIR / script)],
            input=json.dumps(payload),
            cwd=root,
            env=env,
            text=True,
            capture_output=True,
            check=False,
        )

    def create_plan(self, root: Path) -> None:
        (root / "task_plan.md").write_text("# Plan\n\n- active\n", encoding="utf-8")
        (root / "progress.md").write_text("# Progress\n\n- started\n", encoding="utf-8")

    def assert_context_hook(self, result: subprocess.CompletedProcess[str], event: str) -> None:
        self.assertEqual(result.returncode, 0, result.stderr)
        output = json.loads(result.stdout)
        hook_output = output["hookSpecificOutput"]
        self.assertEqual(hook_output["hookEventName"], event)
        self.assertIn("[planning-with-files] ACTIVE PLAN", hook_output["additionalContext"])

    def test_user_prompt_submit_emits_json_context(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            self.create_plan(root)

            result = self.run_hook(
                "user_prompt_submit.py", root, "UserPromptSubmit"
            )

            self.assert_context_hook(result, "UserPromptSubmit")

    def test_session_start_emits_json_context(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            self.create_plan(root)

            result = self.run_hook("session_start.py", root, "SessionStart")

            self.assert_context_hook(result, "SessionStart")

    def test_no_plan_emits_no_output(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            result = self.run_hook(
                "user_prompt_submit.py", Path(temp_dir), "UserPromptSubmit"
            )

            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(result.stdout, "")

    def test_session_isolation_uses_stdin_session_id(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            self.create_plan(root)
            sessions = root / ".planning" / "sessions"
            sessions.mkdir(parents=True)

            unattached = self.run_hook(
                "user_prompt_submit.py", root, "UserPromptSubmit", "unattached"
            )
            self.assertEqual(unattached.stdout, "")

            (sessions / "attached.attached").touch()
            attached = self.run_hook(
                "user_prompt_submit.py", root, "UserPromptSubmit", "attached"
            )
            self.assert_context_hook(attached, "UserPromptSubmit")


if __name__ == "__main__":
    unittest.main()
