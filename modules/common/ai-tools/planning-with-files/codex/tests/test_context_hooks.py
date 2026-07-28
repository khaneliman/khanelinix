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
SKILL_DIR = CODEX_DIR / "skills" / "planning-with-files"
REQUIREMENTS = CODEX_DIR / "requirements.nix"
HOOKS_JSON = CODEX_DIR / "hooks.json"
REPO_ROOT = Path(__file__).resolve().parents[6]
CLAUDE_HOOK = (
    REPO_ROOT
    / "modules/home/programs/terminal/tools/claude-code/hooks/planning-with-files.nix"
)


class ContextHookTests(unittest.TestCase):
    def run_hook(
        self,
        script: str,
        root: Path,
        event: str,
        session_id: str = "test-session",
        source: str | None = None,
        stop_hook_active: bool | None = None,
    ) -> subprocess.CompletedProcess[str]:
        payload = {
            "cwd": str(root),
            "hook_event_name": event,
            "session_id": session_id,
        }
        if source is not None:
            payload["source"] = source
        if stop_hook_active is not None:
            payload["stop_hook_active"] = stop_hook_active
        env = os.environ.copy()
        env["CODEX_SESSIONS_DIR"] = str(root / "codex-sessions")
        env["PWF_SKILL_DIR"] = str(SKILL_DIR)
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
        (root / "task_plan.md").write_text(
            "# Plan\n\n### Phase 1\n**Status:** in_progress\n", encoding="utf-8"
        )
        (root / "progress.md").write_text("# Progress\n\n- started\n", encoding="utf-8")

    def assert_prompt_nudge(self, result: subprocess.CompletedProcess[str]) -> None:
        self.assertEqual(result.returncode, 0, result.stderr)
        output = json.loads(result.stdout)
        hook_output = output["hookSpecificOutput"]
        self.assertEqual(hook_output["hookEventName"], "UserPromptSubmit")
        context = hook_output["additionalContext"]
        self.assertIn("[planning-with-files] Active plan: task_plan.md", context)
        self.assertNotIn("# Plan", context)
        self.assertNotIn("# Progress", context)

    def test_user_prompt_submit_emits_json_context(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            self.create_plan(root)

            result = self.run_hook(
                "user_prompt_submit.py", root, "UserPromptSubmit"
            )

            self.assert_prompt_nudge(result)

    def test_session_start_does_not_repeat_prompt_context(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            self.create_plan(root)

            result = self.run_hook("session_start.py", root, "SessionStart")

            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(result.stdout, "")

    def test_session_start_shell_uses_installed_codex_skill_path(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            skill_scripts = (
                root / "config" / "codex" / "skills" / "planning-with-files" / "scripts"
            )
            skill_scripts.mkdir(parents=True)
            catchup = skill_scripts / "session-catchup.py"
            catchup.write_text("print('catchup-ran')\n", encoding="utf-8")
            env = os.environ.copy()
            env.pop("PWF_SKILL_DIR", None)
            env["XDG_CONFIG_HOME"] = str(root / "config")

            result = subprocess.run(
                ["sh", str(HOOK_DIR / "session-start.sh")],
                cwd=root,
                env=env,
                text=True,
                capture_output=True,
                check=False,
            )

            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn("catchup-ran", result.stdout)

    def test_compact_session_start_restores_concise_nudge(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            self.create_plan(root)

            result = self.run_hook(
                "session_start.py", root, "SessionStart", source="compact"
            )

            self.assertEqual(result.returncode, 0, result.stderr)
            output = json.loads(result.stdout)
            hook_output = output["hookSpecificOutput"]
            self.assertEqual(hook_output["hookEventName"], "SessionStart")
            context = hook_output["additionalContext"]
            self.assertIn("Active plan: task_plan.md", context)
            self.assertNotIn("# Plan", context)

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
            self.assert_prompt_nudge(attached)

    def test_attestation_mismatch_emits_warning_without_plan_body(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            self.create_plan(root)
            (root / ".plan-attestation").write_text("0" * 64, encoding="utf-8")

            result = self.run_hook(
                "user_prompt_submit.py", root, "UserPromptSubmit"
            )

            self.assertEqual(result.returncode, 0, result.stderr)
            output = json.loads(result.stdout)
            context = output["hookSpecificOutput"]["additionalContext"]
            self.assertIn("Plan changed after attestation", context)
            self.assertNotIn("# Plan", context)

    def test_stop_blocks_incomplete_gated_plan(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            self.create_plan(root)
            (root / ".mode").write_text("autonomous gate\n", encoding="utf-8")

            result = self.run_hook(
                "stop.py", root, "Stop", stop_hook_active=False
            )

            self.assertEqual(result.returncode, 0, result.stderr)
            output = json.loads(result.stdout)
            self.assertEqual(output["decision"], "block")
            self.assertIn("Gated plan incomplete", output["reason"])

    def test_recursive_stop_does_not_block(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            self.create_plan(root)
            (root / ".mode").write_text("autonomous gate\n", encoding="utf-8")

            result = self.run_hook(
                "stop.py", root, "Stop", stop_hook_active=True
            )

            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(result.stdout, "")

    def test_managed_hooks_use_recovery_sources_without_precompact(self) -> None:
        requirements = REQUIREMENTS.read_text(encoding="utf-8")
        hooks = json.loads(HOOKS_JSON.read_text(encoding="utf-8"))["hooks"]

        self.assertIn('matcher = "startup|resume|clear|compact";', requirements)
        self.assertNotIn("PreCompact =", requirements)
        self.assertNotIn("PreCompact", hooks)

    def test_claude_adapter_schema_evaluates(self) -> None:
        expression = f'''
          let
            flake = builtins.getFlake {json.dumps(str(REPO_ROOT))};
            pkgs = flake.inputs.nixpkgs.legacyPackages.${{builtins.currentSystem}};
            lib = flake.inputs.nixpkgs.lib;
            aiTools = import {REPO_ROOT}/modules/common/ai-tools {{
              inherit lib pkgs;
              gatewayEnabled = false;
            }};
            hooks = import {CLAUDE_HOOK} {{ inherit aiTools lib pkgs; }};
          in builtins.mapAttrs (_: entries:
            map (entry: map (hook: hook.timeout) entry.hooks) entries
          ) hooks
        '''
        result = subprocess.run(
            ["nix", "eval", "--impure", "--json", "--expr", expression],
            cwd=REPO_ROOT,
            text=True,
            capture_output=True,
            check=False,
        )

        self.assertEqual(result.returncode, 0, result.stderr)
        hooks = json.loads(result.stdout)
        self.assertEqual(
            set(hooks), {"PreCompact", "SessionStart", "Stop", "UserPromptSubmit"}
        )
        self.assertEqual(hooks["SessionStart"], [[30]])
        self.assertEqual(hooks["Stop"], [[30]])


if __name__ == "__main__":
    unittest.main()
