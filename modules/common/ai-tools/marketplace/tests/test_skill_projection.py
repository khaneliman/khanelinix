from __future__ import annotations

import sys
import tempfile
import unittest
from pathlib import Path

MARKETPLACE_DIR = Path(__file__).resolve().parents[1]
AI_TOOLS_DIR = MARKETPLACE_DIR.parent
REPO_ROOT = AI_TOOLS_DIR.parents[2]
SKILLS_DIR = AI_TOOLS_DIR / "skills"
sys.path.insert(0, str(MARKETPLACE_DIR))

import skill_projection

USER_ONLY_SKILLS = {
    "program-orchestration",
}
# Owner-routed domain skills and overlays stay model-visible on Claude Code and
# Pi; Codex hides them from implicit matching to protect the discovery budget.
CODEX_EXPLICIT_ROUTED_SKILLS = {
    "bevy-toolkit",
    "develop-web-game",
    "memory-profiler",
    "multi-provider-sdlc",
    "sarif-toolkit",
    "show-me-your-work",
    "skill-creator",
    "swarm",
}
CODEX_CALLER_ONLY_SKILLS = {
    "arena",
    "interrogate",
    "playwright-interactive",
    "recall",
    "reflect",
    "requirements-interview",
    "unslop",
}


class SkillProjectionTests(unittest.TestCase):
    def test_canonical_invocation_classes_are_exact(self) -> None:
        user_only: set[str] = set()
        codex_explicit: set[str] = set()
        for skill_dir in sorted(SKILLS_DIR.iterdir()):
            manifest = skill_dir / "SKILL.md"
            if not manifest.is_file():
                continue
            if (
                skill_projection.invocation_mode(manifest.read_text(encoding="utf-8"))
                == skill_projection.USER_ONLY_MODE
            ):
                user_only.add(skill_dir.name)
            metadata = skill_dir / "agents" / "openai.yaml"
            if (
                metadata.is_file()
                and "allow_implicit_invocation: false"
                in metadata.read_text(encoding="utf-8")
            ):
                codex_explicit.add(skill_dir.name)

        self.assertEqual(user_only, USER_ONLY_SKILLS)
        self.assertEqual(
            codex_explicit,
            USER_ONLY_SKILLS | CODEX_EXPLICIT_ROUTED_SKILLS | CODEX_CALLER_ONLY_SKILLS,
        )

    def test_provider_controls_preserve_caller_invocation(self) -> None:
        for name in sorted(USER_ONLY_SKILLS):
            manifest = (SKILLS_DIR / name / "SKILL.md").read_text(encoding="utf-8")
            with self.subTest(skill=name, provider="claude-code"):
                self.assertIn(
                    "disable-model-invocation: true",
                    skill_projection.project_manifest(manifest, "claude-code"),
                )
            with self.subTest(skill=name, provider="pi"):
                self.assertIn(
                    "disable-model-invocation: true",
                    skill_projection.project_manifest(manifest, "pi"),
                )
            with self.subTest(skill=name, provider="codex"):
                self.assertNotIn(
                    "disable-model-invocation:",
                    skill_projection.project_manifest(manifest, "codex"),
                )

        for name in sorted(CODEX_CALLER_ONLY_SKILLS):
            manifest = (SKILLS_DIR / name / "SKILL.md").read_text(encoding="utf-8")
            for provider in ("claude-code", "codex", "pi"):
                with self.subTest(skill=name, provider=provider):
                    self.assertNotIn(
                        "disable-model-invocation:",
                        skill_projection.project_manifest(manifest, provider),
                    )

    def test_projection_keeps_canonical_source_portable(self) -> None:
        source_manifest = (SKILLS_DIR / "program-orchestration" / "SKILL.md").read_text(
            encoding="utf-8"
        )
        self.assertNotIn("disable-model-invocation:", source_manifest)

        with tempfile.TemporaryDirectory() as temporary:
            destination = Path(temporary) / "program-orchestration"
            skill_projection.render_path(
                SKILLS_DIR / "program-orchestration",
                destination,
                "claude-code",
            )

            rendered = (destination / "SKILL.md").read_text(encoding="utf-8")
            self.assertEqual(rendered.count("disable-model-invocation: true"), 1)
            self.assertNotIn(
                "__pycache__", {path.name for path in destination.rglob("*")}
            )

    def test_canonical_host_extension_is_rejected(self) -> None:
        manifest = (
            "---\n"
            "name: manual-skill\n"
            "description: Manual skill.\n"
            "disable-model-invocation: true\n"
            "---\n"
        )

        with self.assertRaisesRegex(
            skill_projection.ProjectionError,
            "canonical skills must not declare disable-model-invocation",
        ):
            skill_projection.project_manifest(manifest, "claude-code")

    def test_pi_home_module_installs_projected_tree(self) -> None:
        ai_tools_module = (AI_TOOLS_DIR / "default.nix").read_text(encoding="utf-8")
        pi_module = (
            REPO_ROOT
            / "modules/home/programs/terminal/tools/pi-coding-agent/default.nix"
        ).read_text(encoding="utf-8")

        self.assertIn(
            'piCodingAgent.excludeLocal = [\n      "planning-with-files"\n    ];',
            ai_tools_module,
        )
        self.assertIn(
            "projectedSkills = aiTools.piCodingAgent.skills;",
            pi_module,
        )
        self.assertIn("skills = [ projectedSkills ];", pi_module)


if __name__ == "__main__":
    unittest.main()
