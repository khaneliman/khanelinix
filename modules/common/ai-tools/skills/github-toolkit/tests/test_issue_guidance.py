from __future__ import annotations

import hashlib
import unittest
from pathlib import Path

SKILL_ROOT = Path(__file__).resolve().parents[1]
REFERENCES = SKILL_ROOT / "references"
LICENSE = SKILL_ROOT / "LICENSES" / "LICENSE-matt-pocock.txt"


class IssueGuidanceTests(unittest.TestCase):
    def test_issue_modes_route_durable_agent_handoff(self) -> None:
        creation = (REFERENCES / "issue-creation.md").read_text(encoding="utf-8")
        triage = (REFERENCES / "issue-triage.md").read_text(encoding="utf-8")
        brief = (REFERENCES / "agent-brief.md").read_text(encoding="utf-8")

        self.assertIn("[agent-brief.md](agent-brief.md)", creation)
        self.assertIn("[agent-brief.md](agent-brief.md)", triage)
        self.assertIn("current and desired behavior", brief.lower())
        self.assertIn("independently verifiable acceptance criteria", brief.lower())
        self.assertIn("avoid file paths and line numbers", brief.lower())
        self.assertIn("out of scope", brief.lower())
        self.assertIn("explicit github-write boundary", creation.lower())
        self.assertEqual(
            hashlib.sha256(LICENSE.read_bytes()).hexdigest(),
            "0e7ac423bf2c6e223b7c5b156f8cf72da49d748e56a1641402c31f22ad07dbb5",
        )


if __name__ == "__main__":
    unittest.main()
