from __future__ import annotations

import hashlib
import re
import unittest
from pathlib import Path

SKILL_ROOT = Path(__file__).resolve().parents[1]
SKILL_MD = SKILL_ROOT / "SKILL.md"
REFERENCE = SKILL_ROOT / "references" / "interview-method.md"
LICENSE = SKILL_ROOT / "LICENSE"
OPENAI_METADATA = SKILL_ROOT / "agents" / "openai.yaml"
MATT_LICENSE_SHA256 = "0e7ac423bf2c6e223b7c5b156f8cf72da49d748e56a1641402c31f22ad07dbb5"


def read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def frontmatter(text: str) -> dict[str, str]:
    lines = text.splitlines()
    end = lines[1:].index("---") + 1
    fields = {}
    for line in lines[1:end]:
        key, separator, value = line.partition(":")
        if separator:
            fields[key] = value.strip().strip('"')
    return fields


class RequirementsInterviewContractTests(unittest.TestCase):
    def setUp(self) -> None:
        self.skill = read(SKILL_MD)
        self.reference = read(REFERENCE)

    def test_trigger_description_names_explicit_and_material_choices(self) -> None:
        description = frontmatter(self.skill)["description"].lower()
        for phrase in (
            "explicit interview request",
            "material product choice",
            "frontier",
        ):
            self.assertIn(phrase, description)

    def test_non_trigger_boundary_excludes_routine_implementation(self) -> None:
        combined = self.skill.lower()
        for phrase in (
            "routine implementation",
            "generic clarification",
            "architecture",
        ):
            self.assertIn(phrase, combined)

    def test_authority_contract_assigns_decisions_to_user(self) -> None:
        self.assertIn("make the user the authority", self.reference)
        self.assertIn("Agent:", self.reference)
        self.assertIn("User:", self.reference)
        self.assertIn("Implementer or project owner:", self.reference)

    def test_local_reference_link_resolves(self) -> None:
        targets = re.findall(r"\[[^]]+\]\(([^)]+)\)", self.skill)
        self.assertEqual(targets, ["references/interview-method.md"])
        self.assertTrue((SKILL_ROOT / targets[0]).is_file())

    def test_metadata_and_license_match_contract(self) -> None:
        fields = frontmatter(self.skill)
        self.assertEqual(fields["name"], "requirements-interview")
        self.assertEqual(set(fields), {"name", "description", "license"})
        metadata = read(OPENAI_METADATA)
        self.assertIn("display_name:", metadata)
        self.assertIn("short_description:", metadata)
        self.assertIn("default_prompt:", metadata)
        self.assertEqual(
            hashlib.sha256(LICENSE.read_bytes()).hexdigest(), MATT_LICENSE_SHA256
        )

    def test_artifact_write_requires_explicit_request(self) -> None:
        self.assertIn("Do not write an ADR", self.skill)
        self.assertIn(
            "unless the user explicitly requests", " ".join(self.skill.split())
        )
        self.assertIn(
            "Write an ADR or requirements artifact only after an explicit request",
            self.reference,
        )
        self.assertIn("Confirm\nthe exact path", self.reference)


if __name__ == "__main__":
    unittest.main()
