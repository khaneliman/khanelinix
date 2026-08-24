"""Contract tests for the figure-it-out program lifecycle."""

from __future__ import annotations

import re
import unittest
from pathlib import Path


SKILL_MD = Path(__file__).resolve().parents[1] / "SKILL.md"
MAX_PLAYBOOK_LINES = 100


def body() -> str:
    content = SKILL_MD.read_text(encoding="utf-8")
    return content.split("---", maxsplit=2)[2]


def section(name: str, next_name: str) -> str:
    content = body()
    return content.split(name, maxsplit=1)[1].split(next_name, maxsplit=1)[0]


def normalized(content: str) -> str:
    return " ".join(content.split())


class FigureItOutContract(unittest.TestCase):
    def test_playbook_stays_within_line_budget(self) -> None:
        self.assertLessEqual(len(SKILL_MD.read_text().splitlines()), MAX_PLAYBOOK_LINES)

    def test_program_retains_lifecycle_ownership(self) -> None:
        text = normalized(body()).lower()
        self.assertIn("this skill owns the program lifecycle", text)
        self.assertIn("`verified-slice` stays a unit method", text)
        self.assertIn("does not own program lifecycle", text)

    def test_designs_independently_landable_stack_before_writes(self) -> None:
        text = section("## Phase B", "## Phase C")
        self.assertIn("`git-toolkit`", text)
        self.assertIn("before writes", text.lower())
        self.assertIn("independently landable units", text)
        self.assertIn("rollback boundaries", text)

    def test_each_unit_uses_verified_slice(self) -> None:
        text = normalized(section("## Phase C", "## Phase D")).lower()
        self.assertIn("each planned unit through the `verified-slice`", text)
        self.assertIn("baseline", text)
        self.assertIn("implementation", text)
        self.assertIn("verification", text)
        self.assertIn("review", text)
        self.assertIn("correction", text)

    def test_commit_and_handoff_branches_are_disjoint(self) -> None:
        text = normalized(section("## Phase C", "## Phase D")).lower()
        self.assertRegex(
            text,
            re.compile(
                r"with `local-commit`, commit the candidate, then confirm "
                r"occurrence\. otherwise, hand off the exact patch and stop\."
            ),
        )
        self.assertIn("confirmed occurrence and durable rollback boundary", text)

    def test_audit_trail_uses_show_me_your_work(self) -> None:
        text = section("## Phase D", "## Phase E")
        self.assertIn("`show-me-your-work`", text)
        self.assertIn("one canonical TSV", text)


if __name__ == "__main__":
    unittest.main()
