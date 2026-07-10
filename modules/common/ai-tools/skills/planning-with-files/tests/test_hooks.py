#!/usr/bin/env python3
from __future__ import annotations

import subprocess
import tempfile
import unittest
from pathlib import Path

SKILL_DIR = Path(__file__).resolve().parent.parent
INJECT = SKILL_DIR / "scripts" / "inject-plan.sh"
GATE = SKILL_DIR / "scripts" / "gate-stop.sh"
SKILL = SKILL_DIR / "SKILL.md"


class HookTests(unittest.TestCase):
    def run_script(
        self, script: Path, root: Path, *args: str, stdin: str = ""
    ) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            ["sh", str(script), *args],
            cwd=root,
            input=stdin,
            text=True,
            capture_output=True,
            check=False,
        )

    def create_plan(self, root: Path) -> None:
        (root / "task_plan.md").write_text(
            "# Secret plan body\n\n### Phase 1\n**Status:** in_progress\n",
            encoding="utf-8",
        )
        (root / "progress.md").write_text(
            "# Secret progress body\n", encoding="utf-8"
        )

    def test_prompt_hook_emits_pointer_not_plan_body(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            self.create_plan(root)

            result = self.run_script(INJECT, root, "--context=userprompt")

            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn("Active plan: task_plan.md", result.stdout)
            self.assertNotIn("Secret plan body", result.stdout)
            self.assertNotIn("Secret progress body", result.stdout)

    def test_attestation_mismatch_emits_only_warning(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            self.create_plan(root)
            (root / ".plan-attestation").write_text("0" * 64, encoding="utf-8")

            result = self.run_script(INJECT, root, "--context=userprompt")

            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn("Plan changed after attestation", result.stdout)
            self.assertNotIn("Secret plan body", result.stdout)

    def test_posix_stop_gate_blocks_incomplete_gated_plan(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            self.create_plan(root)
            (root / ".mode").write_text("autonomous gate\n", encoding="utf-8")

            result = self.run_script(
                GATE, root, stdin='{"stop_hook_active":false}\n'
            )

            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn('"decision":"block"', result.stdout)

    def test_skill_has_no_per_tool_recitation_hooks(self) -> None:
        text = SKILL.read_text(encoding="utf-8")
        frontmatter = text.split("---", 2)[1]

        self.assertNotIn("PreToolUse:", frontmatter)
        self.assertNotIn("PostToolUse:", frontmatter)
        self.assertIn("gate-stop.sh", frontmatter)
        self.assertNotIn("powershell.exe", frontmatter)


if __name__ == "__main__":
    unittest.main()
