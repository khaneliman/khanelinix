from __future__ import annotations

import unittest

from support import GateCase


class CommitAttributionTests(GateCase):
    def test_agent_trailers_are_denied_in_commits(self) -> None:
        for command in (
            "git commit -m 'fix(x): y' -m 'Co-authored-by: Claude <noreply@anthropic.com>'",
            "git commit -am 'fix: y\n\nAssisted-by: codex'",
            "git commit -m 'fix(x): y' \\\n  -m 'Co-authored-by: Claude <noreply@anthropic.com>'",
            "git commit -F - <<'EOF'\nfix(x): y\n\nGenerated with Claude Code\nEOF",
            "jj describe -m 'fix: y\n\nCo-authored-by: GPT-6 <x@openai.com>'",
            "git commit -m 'fix: y' --trailer 'Co-authored-by: Claude <noreply@anthropic.com>'",
            "printf 'fix: y\\n\\nCo-authored-by: Claude <noreply@anthropic.com>' | git commit -F -",
        ):
            with self.subTest(command=command):
                self.assert_denied(command, "agent attribution")

    def test_ordinary_commits_pass(self) -> None:
        for command in (
            "git commit -m 'fix(claude-code): track installed version' -m 'Keeps the gateway pin current.'",
            "git commit -m 'feat(x): y' -m 'Co-authored-by: Jane Doe <jane@example.com>'",
            "git commit --amend --no-edit",
        ):
            with self.subTest(command=command):
                self.assert_allowed(command)


if __name__ == "__main__":
    unittest.main()
