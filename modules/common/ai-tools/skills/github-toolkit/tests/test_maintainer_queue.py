"""Contract tests for the GitHub maintainer queue mode."""

from __future__ import annotations

import json
import re
import unittest
from pathlib import Path

SKILL_ROOT = Path(__file__).resolve().parents[1]
SKILL_MD = SKILL_ROOT / "SKILL.md"
REFERENCE = SKILL_ROOT / "references" / "maintainer-queue.md"
PR_REVIEW_REFERENCE = SKILL_ROOT / "references" / "pr-review.md"
BASE_MD = SKILL_ROOT.parents[1] / "base.md"
CATALOG = SKILL_ROOT.parents[1] / "marketplace" / "catalog.json"


def read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def compact(content: str) -> str:
    return " ".join(content.split())


class MaintainerQueueRoutingContract(unittest.TestCase):
    def test_description_names_maintainer_queue_without_budget_growth(self) -> None:
        description = re.search(
            r"^description:\s*(.+)$", read(SKILL_MD), re.MULTILINE
        ).group(1)
        self.assertIn("GitHub maintainer queues", description)
        self.assertLessEqual(len(description), 249)

    def test_root_routes_queue_to_one_reference(self) -> None:
        text = read(SKILL_MD)
        self.assertIn("**maintainer-queue**", text)
        self.assertIn("[maintainer-queue.md](references/maintainer-queue.md)", text)
        self.assertTrue(REFERENCE.is_file())

    def test_base_names_queue_owner(self) -> None:
        if not BASE_MD.is_file():
            self.skipTest("repository base routing is not installed")
        self.assertIn("GitHub queues, issues, PRs", compact(read(BASE_MD)))

    def test_marketplace_description_names_queue(self) -> None:
        if not CATALOG.is_file():
            self.skipTest("marketplace catalog is not installed")
        plugins = json.loads(read(CATALOG))["plugins"]
        entry = next(plugin for plugin in plugins if plugin["name"] == "github-toolkit")
        self.assertIn("GitHub queues", entry["description"])


class MaintainerQueueMethodContract(unittest.TestCase):
    def setUp(self) -> None:
        self.content = read(REFERENCE)
        self.text = compact(self.content).lower()

    def section(self, name: str, next_name: str) -> str:
        return self.content.split(name, maxsplit=1)[1].split(next_name, maxsplit=1)[0]

    def test_bounds_live_snapshot_and_reports_sampling(self) -> None:
        collect = compact(self.section("## Collect", "## Normalize")).lower()
        self.assertIn("issue_scan.py", collect)
        self.assertIn('--query "is:open"', collect)
        self.assertIn("gh pr list", collect)
        self.assertIn("is:pr is:open", collect)
        self.assertIn("incomplete_results: .incomplete_results", collect)
        self.assertIn("bounded", collect)
        self.assertIn("sampling and api limits", collect)
        self.assertIn("`total: unknown`", collect)
        self.assertRegex(
            collect,
            r"for either collector, if its request fails or "
            r"`incomplete_results` is true, report `total: unknown`",
        )
        self.assertIn("security.md", collect)

    def test_collects_policy_targeted_blockers_outside_recent_sample(self) -> None:
        collect = compact(self.section("## Collect", "## Normalize")).lower()
        self.assertIn("policy-targeted", collect)
        self.assertIn("release blockers", collect)
        self.assertIn("supported-branch breakage", collect)
        self.assertIn("deduplicate", collect)
        self.assertIn("exact policy labels", collect)
        self.assertIn("limited to the recent maintainer sample", collect)

    def test_normalizes_actionable_queue_records(self) -> None:
        normalize = self.section("## Normalize", "## Prioritize").lower()
        for field in (
            "kind",
            "number",
            "url",
            "status",
            "evidence",
            "next_action",
            "blocked_by",
            "write_authority",
        ):
            self.assertRegex(normalize, rf"(?m)^{field}$")

    def test_priority_follows_policy_and_evidence(self) -> None:
        prioritize = compact(self.section("## Prioritize", "## Route")).lower()
        self.assertIn("repository policy first", prioritize)
        self.assertIn("release blocker", prioritize)
        self.assertIn("confirmed regression", prioritize)
        self.assertIn("maintainer commitment", prioritize)
        self.assertIn("comment count is not priority", prioritize)

    def test_routes_actions_without_stealing_lifecycle(self) -> None:
        route = compact(self.section("## Route", "## Authority")).lower()
        for mode in ("issue-triage", "pr-review", "pr-feedback", "ci-fix"):
            self.assertIn(f"`{mode}`", route)
        self.assertIn("`engineering-workflow`", route)
        self.assertIn("`figure-it-out`", route)
        self.assertIn("does not own source mutation", route)
        self.assertIn("[agent-brief.md](agent-brief.md)", route)
        self.assertLess(
            route.index("`issue-triage`"), route.index("`engineering-workflow`")
        )

    def test_queue_is_read_only_and_writes_are_item_scoped(self) -> None:
        authority = compact(self.section("## Authority", "## Output")).lower()
        self.assertIn("queue mode is read-only", authority)
        self.assertIn("preview the exact write", authority)
        self.assertIn("one selected item", authority)
        self.assertIn("does not grant another", authority)

    def test_output_separates_now_waiting_and_limits(self) -> None:
        output = self.content.split("## Output", maxsplit=1)[1].lower()
        for term in (
            "act now",
            "waiting",
            "implementation-ready",
            "draft github writes",
            "sampling and api limits",
        ):
            self.assertIn(term, output)
        self.assertIn("live external state", output)
        self.assertIn("durable memory", output)


class PullRequestReviewContract(unittest.TestCase):
    def setUp(self) -> None:
        self.text = compact(read(PR_REVIEW_REFERENCE)).lower()

    def test_findings_are_current_head_and_implementation_ready(self) -> None:
        for requirement in (
            "load every corresponding specialist skill",
            "each changed language or domain",
            "return a blocked review",
            "revalidate each finding against the current pr head",
            "trigger or input",
            "current behavior",
            "expected behavior",
            "concrete correction",
            "condition",
            "type",
            "module assignment",
            "precedence",
            "compatibility",
            "focused regression test that fails before",
            "one defect per comment",
            "what breaks",
            "replacement code shape",
            "proof test",
            "do not restate the diff",
            "abstract repair verbs without an exact operation",
            "owns the protocol or behavior being consumed",
            "pinned commit and exact lines",
            "unresolved choice and viable alternatives",
        ):
            self.assertIn(requirement, self.text)

    def test_pending_mutations_are_previewed_owned_and_never_submitted(self) -> None:
        for requirement in (
            "inspect the exact review and comment ids again",
            "confirm the review is pending and owned by the current actor",
            "preview every planned mutation",
            '`expected_head_sha` and `expected_review_state: "pending"`',
            "validates both during preview and again immediately before mutation",
            "select only the exact review owned by the current actor",
            "never submit it",
        ):
            self.assertIn(requirement, self.text)


if __name__ == "__main__":
    unittest.main()
