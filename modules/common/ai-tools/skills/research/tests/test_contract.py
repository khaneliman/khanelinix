from __future__ import annotations

import hashlib
import re
import unittest
from pathlib import Path

SKILL_ROOT = Path(__file__).resolve().parents[1]
SKILL_MD = SKILL_ROOT / "SKILL.md"
REFERENCE = SKILL_ROOT / "references" / "research-method.md"
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


class ResearchContractTests(unittest.TestCase):
    def setUp(self) -> None:
        self.skill = read(SKILL_MD)
        self.reference = read(REFERENCE)

    def test_trigger_description_names_primary_source_research(self) -> None:
        description = frontmatter(self.skill)["description"].lower()
        for phrase in ("external research", "primary sources", "cited answer"):
            self.assertIn(phrase, description)

    def test_non_trigger_boundary_distinguishes_how_and_why(self) -> None:
        description = frontmatter(self.skill)["description"]
        self.assertIn("repository structure", description)
        self.assertIn("how or why", description)

    def test_authority_contract_requires_sources_to_own_claims(self) -> None:
        combined = self.skill + self.reference
        self.assertIn("source that owns it", combined)
        self.assertIn("Claim:", self.reference)
        self.assertIn("Source:", self.reference)

    def test_local_reference_link_resolves(self) -> None:
        targets = re.findall(r"\[[^]]+\]\(([^)]+)\)", self.skill)
        self.assertEqual(targets, ["references/research-method.md"])
        self.assertTrue((SKILL_ROOT / targets[0]).is_file())

    def test_metadata_and_license_match_contract(self) -> None:
        fields = frontmatter(self.skill)
        self.assertEqual(fields["name"], "research")
        self.assertEqual(set(fields), {"name", "description", "license"})
        metadata = read(OPENAI_METADATA)
        self.assertIn("display_name:", metadata)
        self.assertIn("short_description:", metadata)
        self.assertIn("default_prompt:", metadata)
        self.assertEqual(
            hashlib.sha256(LICENSE.read_bytes()).hexdigest(), MATT_LICENSE_SHA256
        )

    def test_artifact_write_requires_explicit_request(self) -> None:
        self.assertIn("Read-only answer by default", self.skill)
        self.assertIn("explicitly requests a repository artifact", self.skill)
        self.assertIn(
            "Write an artifact only when the user explicitly asks", self.reference
        )
        self.assertIn(
            "Do not create task notes, plans, or ADRs by default", self.reference
        )


if __name__ == "__main__":
    unittest.main()
