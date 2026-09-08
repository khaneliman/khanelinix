from __future__ import annotations

import sys
import unittest
from pathlib import Path

MARKETPLACE_DIR = Path(__file__).resolve().parents[1]
AI_TOOLS_DIR = MARKETPLACE_DIR.parent
SKILLS_DIR = AI_TOOLS_DIR / "skills"
sys.path.insert(0, str(MARKETPLACE_DIR))

import skill_metadata

USER_ONLY_SKILLS = {
    "to-spec",
    "program-orchestration",
}
# Owner-routed domain skills and overlays stay model-visible on Claude Code and
# Pi; Codex hides them from implicit matching to protect the discovery budget.
CODEX_EXPLICIT_ROUTED_SKILLS = {
    "bevy-toolkit",
    "develop-web-game",
    "memory-profiler",
    "sarif-toolkit",
    "show-me-your-work",
    "skill-creator",
    "swarm",
}
CODEX_CALLER_ONLY_SKILLS = {
    "arena",
    "playwright-interactive",
    "recall",
    "reflect",
    "requirements-interview",
}


class SkillMetadataTests(unittest.TestCase):
    def test_canonical_invocation_classes_are_exact(self) -> None:
        user_only: set[str] = set()
        codex_explicit: set[str] = set()
        for skill_dir in sorted(SKILLS_DIR.iterdir()):
            manifest = skill_dir / "SKILL.md"
            if not manifest.is_file():
                continue
            manifest_text = manifest.read_text(encoding="utf-8")
            if (
                skill_metadata.invocation_mode(manifest_text)
                == skill_metadata.USER_ONLY_MODE
            ):
                user_only.add(skill_dir.name)
                self.assertEqual(
                    manifest_text.count("disable-model-invocation: true"), 1
                )
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

    def test_native_flag_requires_matching_user_only_metadata(self) -> None:
        native = (
            "---\n"
            "name: manual-skill\n"
            "metadata:\n"
            '  khanelinix-invocation-mode: "user-only"\n'
            "disable-model-invocation: true\n"
            "---\n"
        )
        self.assertEqual(
            skill_metadata.invocation_mode(native),
            skill_metadata.USER_ONLY_MODE,
        )

        with self.assertRaisesRegex(
            skill_metadata.MetadataError,
            "requires khanelinix-invocation-mode: user-only",
        ):
            skill_metadata.invocation_mode(native.replace("metadata:\n", ""))

        with self.assertRaisesRegex(
            skill_metadata.MetadataError,
            "disable-model-invocation must be true",
        ):
            skill_metadata.invocation_mode(native.replace("true", "false"))

    def test_native_flag_rejects_duplicates(self) -> None:
        manifest = (
            "---\n"
            "name: manual-skill\n"
            "metadata:\n"
            '  khanelinix-invocation-mode: "user-only"\n'
            "disable-model-invocation: true\n"
            "disable-model-invocation: true\n"
            "---\n"
        )
        with self.assertRaisesRegex(
            skill_metadata.MetadataError,
            "duplicate disable-model-invocation",
        ):
            skill_metadata.invocation_mode(manifest)

    def test_malformed_frontmatter_is_rejected(self) -> None:
        malformed_manifests = (
            "name: manual-skill\n",
            "---\nname: manual-skill\n",
            "---\ndisable-model-invocation true\n---\n",
            "---\nmetadata: inline\n---\n",
        )
        for manifest in malformed_manifests:
            with (
                self.subTest(manifest=manifest),
                self.assertRaises(skill_metadata.MetadataError),
            ):
                skill_metadata.invocation_mode(manifest)


if __name__ == "__main__":
    unittest.main()
