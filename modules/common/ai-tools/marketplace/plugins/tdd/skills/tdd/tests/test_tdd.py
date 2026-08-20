"""Contract tests for the canonical tdd skill package."""

from __future__ import annotations

import re
import unittest
from pathlib import Path

SKILL_ROOT = Path(__file__).resolve().parents[1]
SKILL_MD = SKILL_ROOT / "SKILL.md"
REFERENCES = SKILL_ROOT / "references"
LICENSES = SKILL_ROOT / "LICENSES"
OPENAI_METADATA = SKILL_ROOT / "agents" / "openai.yaml"

LINK_RE = re.compile(r"!?\[[^\]]*\]\(([^)]+)\)")
SUPPORTED_FRONTMATTER_FIELDS = {"description", "license", "metadata", "name"}
MAX_DESCRIPTION_CHARACTERS = 512
MAX_PLAYBOOK_LINES = 100


def read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def split_frontmatter(content: str) -> tuple[dict[str, str], str]:
    lines = content.splitlines()
    if not lines or lines[0].strip() != "---":
        raise AssertionError("SKILL.md must open with a frontmatter fence")
    end = next(
        index for index, line in enumerate(lines[1:], start=1) if line.strip() == "---"
    )
    fields: dict[str, str] = {}
    for line in lines[1:end]:
        if not line.strip():
            continue
        key, separator, value = line.partition(":")
        if not separator:
            raise AssertionError(f"unparsable frontmatter line: {line}")
        fields[key.strip()] = value.strip()
    return fields, "\n".join(lines[end + 1 :])


def markdown_targets(path: Path) -> list[str]:
    return [
        target.split("#", 1)[0].strip()
        for target in LINK_RE.findall(read(path))
        if not target.startswith(("http://", "https://", "mailto:"))
    ]


class TddFrontmatterContract(unittest.TestCase):
    def setUp(self) -> None:
        self.fields, self.body = split_frontmatter(read(SKILL_MD))

    def test_name_is_tdd(self) -> None:
        self.assertEqual(self.fields.get("name"), "tdd")

    def test_only_supported_fields_are_declared(self) -> None:
        self.assertTrue(set(self.fields).issubset(SUPPORTED_FRONTMATTER_FIELDS))

    def test_description_stays_within_budget(self) -> None:
        description = self.fields.get("description", "")
        self.assertTrue(description)
        self.assertLessEqual(len(description), MAX_DESCRIPTION_CHARACTERS)

    def test_description_names_triggers(self) -> None:
        description = self.fields["description"].lower()
        self.assertIn("test-first", description)
        self.assertIn("red-green-refactor", description)
        self.assertIn("seam", description)

    def test_playbook_stays_under_line_budget(self) -> None:
        self.assertLess(len(read(SKILL_MD).splitlines()), MAX_PLAYBOOK_LINES)


class TddPlaybookContract(unittest.TestCase):
    def setUp(self) -> None:
        _, self.body = split_frontmatter(read(SKILL_MD))

    def test_all_referenced_files_exist(self) -> None:
        for md_path in [SKILL_MD, *REFERENCES.glob("*.md")]:
            for target in markdown_targets(md_path):
                if not target:
                    continue
                target_path = (md_path.parent / target).resolve()
                self.assertTrue(
                    target_path.exists(),
                    f"broken link from {md_path} to {target}",
                )

    def test_declares_narrow_implement_scope(self) -> None:
        lowered = " ".join(self.body.lower().split())
        self.assertIn("narrow implementation method", lowered)
        self.assertIn("does not own lifecycle planning", lowered)
        self.assertIn("external handoff", lowered)

    def test_requires_red_green_refactor_steps(self) -> None:
        lowered = self.body.lower()
        self.assertIn("failing test", lowered)
        self.assertIn("failure evidence", lowered)
        self.assertIn("minimal", lowered)
        self.assertIn("rerun", lowered)
        self.assertIn("refactoring", lowered)

    def test_requires_vertical_slices(self) -> None:
        lowered = self.body.lower()
        self.assertIn("vertical slices", lowered)
        self.assertIn("one seam, one failing test", lowered)

    def test_handles_impractical_test_scenarios(self) -> None:
        lowered = self.body.lower()
        self.assertIn("impractical", lowered)
        self.assertIn("closest executable check", lowered)


class TddReferencesContract(unittest.TestCase):
    def test_test_quality_anti_patterns(self) -> None:
        content = read(REFERENCES / "test-quality.md").lower()
        self.assertIn("observable behavior", content)
        self.assertIn("implementation coupling", content)
        self.assertIn("tautological", content)
        self.assertIn("horizontal slicing", content)
        self.assertIn("vertical slicing", content)

    def test_mocking_guidelines(self) -> None:
        content = read(REFERENCES / "mocking.md").lower()
        self.assertIn("system boundaries only", content)
        self.assertIn("never mock", content)
        self.assertIn("dependency injection", content)


class TddLicensesContract(unittest.TestCase):
    def test_pstack_license_matches(self) -> None:
        pstack = read(LICENSES / "LICENSE-pstack.txt")
        self.assertIn("Copyright (c) 2026 Lauren Tan", pstack)
        self.assertIn("MIT License", pstack)

    def test_matt_pocock_license_matches(self) -> None:
        matt = read(LICENSES / "LICENSE-matt-pocock.txt")
        self.assertIn("Copyright (c) 2026 Matt Pocock", matt)
        self.assertIn("MIT License", matt)


class TddOpenAIMetadataContract(unittest.TestCase):
    def setUp(self) -> None:
        content = read(OPENAI_METADATA)
        self.values: dict[str, str] = {}
        for line in content.splitlines():
            match = re.match(r'^\s{2}([a-z_]+):\s*"(.*)"\s*$', line)
            if match:
                self.values[match.group(1)] = match.group(2)

    def test_interface_mapping_exists(self) -> None:
        self.assertEqual(
            set(self.values),
            {"default_prompt", "display_name", "short_description"},
        )

    def test_short_description_budget(self) -> None:
        self.assertTrue(25 <= len(self.values["short_description"]) <= 64)

    def test_default_prompt_invokes_skill(self) -> None:
        self.assertIn("$tdd", self.values["default_prompt"])


if __name__ == "__main__":
    unittest.main()
