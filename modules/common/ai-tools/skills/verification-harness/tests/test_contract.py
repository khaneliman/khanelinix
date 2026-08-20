from __future__ import annotations

import re
import unittest
from pathlib import Path

SKILL_ROOT = Path(__file__).resolve().parents[1]
SKILL_MD = SKILL_ROOT / "SKILL.md"
LICENSE = SKILL_ROOT / "LICENSE"
METADATA = SKILL_ROOT / "agents" / "openai.yaml"
CANONICAL_LICENSE = SKILL_ROOT.parent / "engineering-workflow" / "LICENSE"


def read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def split_frontmatter(content: str) -> tuple[dict[str, str], str]:
    lines = content.splitlines()
    assert lines[0] == "---"
    end = next(index for index, line in enumerate(lines[1:], 1) if line == "---")
    fields = {
        key.strip(): value.strip()
        for key, separator, value in (line.partition(":") for line in lines[1:end])
        if separator
    }
    return fields, "\n".join(lines[end + 1 :])


class VerificationHarnessContract(unittest.TestCase):
    def test_package_files_exist(self) -> None:
        self.assertTrue(SKILL_MD.is_file())
        self.assertTrue(LICENSE.is_file())
        self.assertTrue(METADATA.is_file())

    def test_frontmatter_and_triggers(self) -> None:
        fields, _ = split_frontmatter(read(SKILL_MD))
        self.assertEqual(fields["name"], "verification-harness")
        description = fields["description"].lower()
        for term in ("create", "audit", "deterministic", "do not use only to run"):
            self.assertIn(term, description)

    def test_modes_distinguish_creation_and_audit_from_run(self) -> None:
        _, body = split_frontmatter(read(SKILL_MD))
        for term in ("**Create.", "**Audit."):
            self.assertIn(term, body)
        self.assertNotIn("**Run.", body)
        self.assertIn("does not own ordinary check execution", " ".join(body.split()))

    def test_harness_contract_is_observable_and_maintained(self) -> None:
        _, body = split_frontmatter(read(SKILL_MD))
        body = " ".join(body.split())
        for term in (
            "feature/check map",
            "observable outcome",
            "minimal command",
            "After behavior changes",
            "explicit gaps",
        ):
            self.assertIn(term, body)

    def test_boundaries_reject_lifecycle_ownership(self) -> None:
        _, body = split_frontmatter(read(SKILL_MD))
        self.assertRegex(body, r"caller owns lifecycle, architecture, final judgment")
        self.assertIn("external writes", body)

    def test_license_matches_existing_pstack_license(self) -> None:
        self.assertEqual(read(LICENSE), read(CANONICAL_LICENSE))

    def test_openai_metadata_contract(self) -> None:
        content = read(METADATA)
        for field in ("display_name", "short_description", "default_prompt"):
            self.assertRegex(content, re.compile(rf'^  {field}: ".+"$', re.MULTILINE))
        self.assertIn("$verification-harness", content)


if __name__ == "__main__":
    unittest.main()
