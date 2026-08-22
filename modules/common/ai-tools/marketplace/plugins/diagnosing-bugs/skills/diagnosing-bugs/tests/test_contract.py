from __future__ import annotations

import hashlib
import re
import unittest
from pathlib import Path

SKILL_ROOT = Path(__file__).resolve().parents[1]
SKILL_MD = SKILL_ROOT / "SKILL.md"
REFERENCE = SKILL_ROOT / "references" / "diagnosis-loop.md"
LICENSE = SKILL_ROOT / "LICENSE"
OPENAI_METADATA = SKILL_ROOT / "agents" / "openai.yaml"
MATT_LICENSE_SHA256 = "0e7ac423bf2c6e223b7c5b156f8cf72da49d748e56a1641402c31f22ad07dbb5"


def read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def description() -> str:
    match = re.search(r'^description:\s*"(.*)"$', read(SKILL_MD), re.MULTILINE)
    assert match is not None
    return match.group(1).lower()


class DiagnosingBugsContractTests(unittest.TestCase):
    def test_trigger_and_boundary_are_discriminating(self) -> None:
        text = description()
        for trigger in ("broken", "failing", "throwing", "flaky", "incorrect"):
            self.assertIn(trigger, text)
        self.assertIn("read-only by default", text)
        self.assertIn("engineering-workflow owns the lifecycle", text)
        self.assertIn("performance-forensics", text)

    def test_root_playbook_is_lean_and_routes_detail(self) -> None:
        text = read(SKILL_MD)
        self.assertLess(len(text.splitlines()), 100)
        self.assertIn("references/diagnosis-loop.md", text)
        self.assertTrue(REFERENCE.is_file())

    def test_diagnosis_loop_preserves_high_value_invariants(self) -> None:
        text = " ".join((read(SKILL_MD) + read(REFERENCE)).lower().split())
        for invariant in (
            "user's exact symptom",
            "every remaining element is load-bearing",
            "three to five falsifiable hypotheses",
            "one variable",
            "[debug-<id>]",
            "original unminimized command",
        ):
            self.assertIn(invariant, text)

    def test_diagnosis_only_stops_before_implementation(self) -> None:
        text = read(SKILL_MD).lower()
        self.assertIn("for diagnosis-only work, stop after the evidence report", text)
        self.assertIn("that lifecycle owns implementation", text)

    def test_diagnosis_probes_preserve_unapproved_state(self) -> None:
        text = " ".join((read(SKILL_MD) + read(REFERENCE)).lower().split())
        self.assertIn("change external state", text)
        self.assertIn("documented non-mutating contract", text)
        self.assertIn("fresh temporary directory", text)
        self.assertIn("caller's working copy", text)
        self.assertIn("separately authorized the exact mutation", text)

    def test_metadata_and_upstream_license_match_contract(self) -> None:
        metadata = read(OPENAI_METADATA)
        self.assertIn("$diagnosing-bugs", metadata)
        self.assertEqual(
            hashlib.sha256(LICENSE.read_bytes()).hexdigest(), MATT_LICENSE_SHA256
        )


if __name__ == "__main__":
    unittest.main()
