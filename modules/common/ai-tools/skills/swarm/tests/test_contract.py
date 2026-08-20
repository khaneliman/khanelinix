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


class SwarmContract(unittest.TestCase):
    def test_package_files_exist(self) -> None:
        self.assertTrue(SKILL_MD.is_file())
        self.assertTrue(LICENSE.is_file())
        self.assertTrue(METADATA.is_file())

    def test_frontmatter_requires_explicit_host_only_trigger(self) -> None:
        fields, body = split_frontmatter(read(SKILL_MD))
        self.assertEqual(fields["name"], "swarm")
        description = fields["description"].lower()
        for term in ("host-only", "explicit", "/swarm", "swarm this"):
            self.assertIn(term, description)
        self.assertIn("Do not implicitly invoke", " ".join(body.split()))

    def test_fanout_contract_is_bounded_and_packetized(self) -> None:
        _, body = split_frontmatter(read(SKILL_MD))
        for term in (
            "independent coverage slices",
            "one write owner per path",
            "Cap worker concurrency",
            "evidence packet",
            "available concurrency cap",
        ):
            self.assertIn(term, body)

    def test_parent_owns_integration_and_external_actions(self) -> None:
        _, body = split_frontmatter(read(SKILL_MD))
        for term in (
            "Return packets to the parent for integration",
            "lifecycle",
            "architecture",
            "final judgment",
            "external writes",
        ):
            self.assertIn(term, body)

    def test_distinguishes_arena_and_multi_provider(self) -> None:
        _, body = split_frontmatter(read(SKILL_MD))
        self.assertRegex(body, r"`arena`.*competing candidates")
        self.assertRegex(
            body, r"`multi-provider-sdlc`.*provider or model seat selection"
        )

    def test_license_matches_existing_pstack_license(self) -> None:
        self.assertEqual(read(LICENSE), read(CANONICAL_LICENSE))

    def test_openai_metadata_disables_implicit_invocation(self) -> None:
        content = read(METADATA)
        for field in ("display_name", "short_description", "default_prompt"):
            self.assertRegex(content, re.compile(rf"^  {field}: \".+\"$", re.MULTILINE))
        self.assertIn("$swarm", content)
        self.assertIn("allow_implicit_invocation: false", content)


if __name__ == "__main__":
    unittest.main()
