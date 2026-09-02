from __future__ import annotations

import unittest
from pathlib import Path

SKILL = Path(__file__).resolve().parents[1] / "SKILL.md"
REFERENCE = SKILL.parent / "references" / "verified-slice.md"
AI_TOOLS_ROOT = SKILL.parents[2]
GENERATED_REFERENCE = (
    AI_TOOLS_ROOT
    / "marketplace"
    / "plugins"
    / "engineering-principles"
    / "skills"
    / "engineering-principles"
    / "references"
    / "verified-slice.md"
)


def normalized(path: Path) -> str:
    return " ".join(path.read_text(encoding="utf-8").lower().split())


class VerifiedSliceContractTests(unittest.TestCase):
    def test_index_routes_to_shared_slice_contract(self) -> None:
        skill = SKILL.read_text(encoding="utf-8")

        self.assertIn("Seventeen principles", skill)
        self.assertIn("[verified-slice](references/verified-slice.md)", skill)

    def test_contract_enforces_ownership_and_authority(self) -> None:
        text = normalized(REFERENCE)

        self.assertIn("does not select the task workflow", text)
        self.assertIn("`workspace-only`: edit, verify, and review. do not stage", text)
        self.assertIn("a local-commit grant implies none of them", text)
        self.assertIn("ordinary advancement of the currently checked-out local branch only", text)
        for forbidden in (
            "branch creation",
            "branch deletion",
            "branch reset",
            "force-moving a branch",
            "another ref mutation",
        ):
            self.assertIn(forbidden, text)
        self.assertIn("do not stack several uncommitted slices", text)
        self.assertIn("do not create a knowingly broken commit", text)

    def test_loop_orders_review_receipt_commit_and_confirmation(self) -> None:
        text = normalized(REFERENCE)
        ordered = (
            "**ground.**",
            "**baseline.**",
            "**implement.**",
            "**verify.**",
            "**review.**",
            "**correct.**",
            "**prepare candidate.**",
            "**bind evidence.**",
            "**commit or hand off.**",
            "**confirm occurrence.**",
            "**advance.**",
        )

        positions = [text.index(marker) for marker in ordered]
        self.assertEqual(positions, sorted(positions))
        self.assertIn("the lifecycle owner validates reviewer findings", text)
        self.assertIn("one correction and one re-review", text)
        self.assertIn("if slice changes cannot be separated", text)
        self.assertIn("stop before another shared-tree slice", text)

    def test_receipt_matches_committed_content(self) -> None:
        text = normalized(REFERENCE)

        for field in (
            "base_commit",
            "base_state_digest",
            "content_digest",
            "candidate_form",
            "commit_sha",
            "receipt_content_digest",
            "committed_content_digest",
            "digest_match",
        ):
            self.assertIn(field, text)
        self.assertIn(
            "the committed content digest must equal the receipt content digest",
            text,
        )
        self.assertIn("mark the occurrence `not_verified`", text)
        self.assertIn("does not prove semantic equivalence", text)
        self.assertIn("a rebase, parent rewrite, or changed dependency base", text)
        self.assertIn("`../scripts/content_digest.py --staged`", text)
        self.assertIn("`../scripts/content_digest.py --worktree [base]`", text)
        self.assertIn("`../scripts/content_digest.py --committed commit`", text)
        self.assertIn("length-prefixed side, path, mode, blob oid", text)
        self.assertIn("raw blob-content records", text)
        self.assertIn("raw leading colon", text)
        self.assertIn("without requiring utf-8", text)
        self.assertIn("changed-path blob-content identity", text)
        self.assertIn("does not prove patch-byte identity", text)

    def test_tool_path_resolves_from_the_reference_directory(self) -> None:
        tool = (REFERENCE.parent / "../scripts/content_digest.py").resolve()

        self.assertTrue(tool.is_file())

    def test_workspace_only_candidates_have_a_digest_mode(self) -> None:
        text = normalized(REFERENCE)

        self.assertIn("`candidate_form` `patch` selects `--worktree`", text)
        self.assertIn("reads the worktree without staging or committing", text)
        self.assertIn("every mode fails when its selected diff contains zero", text)

    def test_committed_digest_takes_one_commit(self) -> None:
        text = normalized(REFERENCE)

        self.assertNotIn("parent_sha..commit_sha", text)
        self.assertIn("derives the first parent and digests that diff", text)
        self.assertIn("merge commit therefore digests the first-parent diff only", text)

    def test_trivial_risk_waives_optional_records(self) -> None:
        text = normalized(REFERENCE)

        self.assertIn("focused verification is required. fresh review is optional", text)
        self.assertIn(
            "pre-commit receipt and commit occurrence records are optional", text
        )
        self.assertIn("reports the focused verification evidence directly", text)

    def test_red_commit_policy_matches_the_sequencing_principle(self) -> None:
        text = normalized(REFERENCE)
        sequencing = normalized(REFERENCE.parent / "sequence-verifiable-units.md")

        self.assertIn("unless repository policy explicitly permits", text)
        self.assertIn("unless repository policy explicitly permits", sequencing)

    def test_generated_reference_matches_canonical_source(self) -> None:
        if AI_TOOLS_ROOT.name != "ai-tools":
            self.skipTest("canonical AI-tools tree is not installed")

        self.assertEqual(REFERENCE.read_bytes(), GENERATED_REFERENCE.read_bytes())


if __name__ == "__main__":
    unittest.main()
