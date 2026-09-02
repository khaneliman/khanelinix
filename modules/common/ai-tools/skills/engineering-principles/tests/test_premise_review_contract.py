from __future__ import annotations

import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

SKILL_ROOT = Path(__file__).resolve().parents[1]
AI_TOOLS_ROOT = SKILL_ROOT.parents[1]
SKILL_MD = SKILL_ROOT / "SKILL.md"
REFERENCE = SKILL_ROOT / "references" / "premise-review.md"
SCRIPT = SKILL_ROOT / "scripts" / "premise_gate_check.py"
FIXTURES = SKILL_ROOT / "tests" / "fixtures" / "premise-review"
SKILLS = SKILL_ROOT.parent
GENERATED_REFERENCE = (
    AI_TOOLS_ROOT
    / "marketplace"
    / "plugins"
    / "engineering-principles"
    / "skills"
    / "engineering-principles"
    / "references"
    / "premise-review.md"
)


def normalized(path: Path) -> str:
    return " ".join(path.read_text(encoding="utf-8").lower().split())


def run_check(mode: str, path: Path) -> tuple[int, dict[str, object]]:
    result = subprocess.run(
        [sys.executable, "-B", str(SCRIPT), mode, str(path)],
        capture_output=True,
        text=True,
        check=False,
    )
    return result.returncode, json.loads(result.stdout)


def rules(report: dict[str, object]) -> set[str]:
    return {failure["rule"] for failure in report["failures"]}  # type: ignore[index]


class PremiseReviewReferenceTests(unittest.TestCase):
    def test_index_routes_review_to_the_premise_gate(self) -> None:
        skill = SKILL_MD.read_text(encoding="utf-8")

        self.assertIn("Seventeen principles", skill)
        self.assertIn("[premise-review](references/premise-review.md)", skill)
        self.assertIn("before checking whether", skill.lower())

    def test_gate_asks_every_concern_as_a_conventional_comment(self) -> None:
        text = normalized(REFERENCE)
        ordered = (
            "note: problem:",
            "note: solves:",
            "note: issue fit:",
            "note: existing capability:",
            "note: native abstraction:",
            "note: api boundary:",
            "note: removable diff:",
            "note: bundling:",
            "note: handed premise:",
            "note: reason not to merge:",
        )
        positions = [text.index(marker) for marker in ordered]
        self.assertEqual(positions, sorted(positions))
        self.assertIn("conventionalcomments.org", text)
        self.assertIn("`issue (blocking):` when it should stop the merge", text)
        self.assertIn("decorate every `issue` and `todo` in the gate explicitly", text)
        self.assertNotIn("p1", text.replace("p1 ", "").replace("p10", ""))

    def test_review_order_puts_premise_before_correctness(self) -> None:
        text = normalized(REFERENCE)
        stages = (
            "1. premise and demonstrated value.",
            "2. issue fit and scope.",
            "3. api and architecture.",
            "4. diff minimality and unrelated noise.",
            "5. behavioral correctness and integration.",
            "6. tests, docs, and policy compliance.",
        )
        positions = [text.index(stage) for stage in stages]
        self.assertEqual(positions, sorted(positions))

    def test_green_ci_is_supporting_evidence(self) -> None:
        text = normalized(REFERENCE)

        self.assertIn("supporting evidence, not the purpose of review", text)
        self.assertIn("closing or redesigning a fully green change", text)
        self.assertIn(
            "`no issues found` and `approved` mean the premise, scope, api boundary, and minimality were checked",
            text,
        )

    def test_packets_require_one_blind_seat_and_reject_shared_premises(self) -> None:
        text = normalized(REFERENCE)

        self.assertIn("at least one reviewer receives a `blind` packet", text)
        self.assertIn("without the author's claims, the chosen solution, or the extraction boundary", text)
        self.assertIn("reviewers that share one unchallenged premise are one reviewer", text)
        self.assertIn("outranks implementation consensus", text)

    def test_regression_case_is_recorded_without_ecosystem_lock_in(self) -> None:
        text = normalized(REFERENCE)

        self.assertIn("#9893", text)
        self.assertIn("non-nix cases", text)
        self.assertTrue((FIXTURES / "review-clean-approve.md").is_file())
        self.assertNotIn("nix", normalized(FIXTURES / "review-clean-approve.md"))
        self.assertNotIn("nix", normalized(FIXTURES / "review-gate-rubber-stamp.md"))

    def test_generated_reference_matches_canonical_source(self) -> None:
        if AI_TOOLS_ROOT.name != "ai-tools":
            self.skipTest("canonical AI-tools tree is not installed")

        self.assertEqual(REFERENCE.read_bytes(), GENERATED_REFERENCE.read_bytes())


class PremiseGateCheckerTests(unittest.TestCase):
    def test_implementation_only_review_fails(self) -> None:
        code, report = run_check("review", FIXTURES / "review-implementation-only.md")

        self.assertEqual(code, 1)
        self.assertIn("missing_gate", rules(report))

    def test_review_that_names_the_native_abstraction_passes(self) -> None:
        code, report = run_check("review", FIXTURES / "review-premise-gate.md")

        self.assertEqual(code, 0, report)
        self.assertEqual(report["details"]["final_verdict"], "changes_requested")
        self.assertIn("native abstraction", report["details"]["blocking"])
        self.assertIn("removable diff", report["details"]["blocking"])
        self.assertFalse(report["details"]["clean"])

    def test_gate_that_finds_a_native_abstraction_cannot_approve(self) -> None:
        code, report = run_check("review", FIXTURES / "review-gate-rubber-stamp.md")

        self.assertEqual(code, 1)
        self.assertEqual(rules(report), {"verdict_contradicts_gate"})

    def test_clean_gate_may_approve(self) -> None:
        code, report = run_check("review", FIXTURES / "review-clean-approve.md")

        self.assertEqual(code, 0, report)
        self.assertTrue(report["details"]["clean"])

    def test_gate_after_findings_or_verdict_fails(self) -> None:
        source = (FIXTURES / "review-clean-approve.md").read_text(encoding="utf-8")
        head, gate_and_rest = source.split("## Premise gate\n", 1)
        gate, rest = gate_and_rest.split("## Findings\n", 1)
        reordered = head + "## Findings\n" + rest + "\n## Premise gate\n" + gate
        with tempfile.TemporaryDirectory() as scratch:
            path = Path(scratch) / "review.md"
            path.write_text(reordered, encoding="utf-8")
            code, report = run_check("review", path)

        self.assertEqual(code, 1)
        self.assertLessEqual({"gate_after_findings", "gate_after_verdict"}, rules(report))

    def test_comment_without_evidence_fails(self) -> None:
        code, report = run_check("review", self.variant("note: existing capability:"))

        self.assertEqual(code, 1)
        self.assertEqual(rules(report), {"unsupported_comment"})

    def test_undecorated_issue_in_gate_fails(self) -> None:
        code, report = run_check(
            "review", self.variant("issue: existing capability: none. Searched src/cli.")
        )

        self.assertEqual(code, 1)
        self.assertEqual(rules(report), {"undecorated_issue"})

    def test_unknown_or_missing_concern_fails(self) -> None:
        code, report = run_check(
            "review", self.variant("note: vibes: the change feels right.")
        )

        self.assertEqual(code, 1)
        self.assertEqual(rules(report), {"unknown_concern", "missing_concerns"})

    def variant(self, replacement_line: str) -> Path:
        source = (FIXTURES / "review-clean-approve.md").read_text(encoding="utf-8")
        edited = "\n".join(
            replacement_line if line.startswith("note: existing capability:") else line
            for line in source.splitlines()
        )
        self.scratch = tempfile.TemporaryDirectory()
        self.addCleanup(self.scratch.cleanup)
        path = Path(self.scratch.name) / "review.md"
        path.write_text(edited, encoding="utf-8")
        return path

    def test_packet_that_asserts_the_extraction_fails(self) -> None:
        code, report = run_check("packet", FIXTURES / "packet-before.md")

        self.assertEqual(code, 1)
        details = {failure["detail"] for failure in report["failures"]}
        self.assertIn("packet lacks 'problem'", details)
        self.assertIn("packet lacks 'independence'", details)
        self.assertIn("required evidence does not name the premise gate", details)

    def test_blind_packet_passes(self) -> None:
        code, report = run_check("packet", FIXTURES / "packet-after.md")

        self.assertEqual(code, 0, report)
        self.assertEqual(report["details"]["independence"], "blind")

    def test_blind_packet_with_author_claims_fails(self) -> None:
        source = (FIXTURES / "packet-after.md").read_text(encoding="utf-8")
        leaked = source + "- Author claims: accountOrder is the agreed extraction.\n"
        with tempfile.TemporaryDirectory() as scratch:
            path = Path(scratch) / "packet.md"
            path.write_text(leaked, encoding="utf-8")
            code, report = run_check("packet", path)

        self.assertEqual(code, 1)
        self.assertEqual(rules(report), {"blind_packet_leaks_solution"})

    def test_informed_packet_may_carry_author_claims(self) -> None:
        source = (FIXTURES / "packet-after.md").read_text(encoding="utf-8")
        informed = source.replace("- Independence: blind", "- Independence: informed")
        informed += "- Author claims: ordering must precede the account-model migration.\n"
        with tempfile.TemporaryDirectory() as scratch:
            path = Path(scratch) / "packet.md"
            path.write_text(informed, encoding="utf-8")
            code, report = run_check("packet", path)

        self.assertEqual(code, 0, report)

    def test_unreadable_input_is_invalid(self) -> None:
        result = subprocess.run(
            [sys.executable, "-B", str(SCRIPT), "review", str(FIXTURES / "missing.md")],
            capture_output=True,
            text=True,
            check=False,
        )

        self.assertEqual(result.returncode, 2)


if __name__ == "__main__":
    unittest.main()
