from __future__ import annotations

import shlex
import unittest

from support import GateCase


class PublicTextTests(GateCase):
    def test_disclosures_in_public_text_are_denied(self) -> None:
        self.say("post the reply")
        for body in (
            "Per AGENTS.md this needs a test.",
            "Tested with Claude Code: all green.",
            "Validated by a subagent against the new head.",
            "Generated with Claude Code",
            "Assisted-by: codex",
            "Checked with review_threads.py before posting.",
            "Looks good — merging soon.",
            "Per `AGENTS.md` this needs a test.",
            "Checked with `review_threads.py` before posting.",
            "Tested with `claude`.",
        ):
            with self.subTest(body=body):
                self.assert_denied(
                    f"gh pr comment 1 --body {shlex.quote(body)}", "prose rules"
                )

    def test_ordinary_public_text_passes(self) -> None:
        self.say("post the reply")
        for body in (
            "claude-code: 2.1.0 -> 2.2.0",
            "Bumps vimPlugins.CopilotChat-nvim and codecompanion-nvim.",
            "Tested: `nix run .#tests -- aerc` (7 passed).",
            "> Tested with Claude Code\n\nThat quote came from the issue; the real check is below.",
            "```\nclaude --version\n```",
            "Tested with copilot.lua loaded; completions work.",
            "Ran with an agent forwarding config on the build host.",
            "Run `claude --version` to check.",
            "Set `programs.claude-code.enable = true` and rebuild.",
            "Bump `codex` to 0.50.",
        ):
            with self.subTest(body=body):
                self.assert_allowed(f"gh pr comment 1 --body {shlex.quote(body)}")

    def test_body_files_and_heredocs_are_read(self) -> None:
        self.say("post the reply")
        body = self.work / "reply.md"
        body.write_text("Per CLAUDE.md, please add a test.\n")
        self.assert_denied(
            "gh pr comment 1 --body-file reply.md", "agent instruction file"
        )
        self.assert_denied(
            "gh pr comment 1 --body-file - <<'EOF'\nTested with Codex.\nEOF",
            "agent process disclosure",
        )
        self.assert_denied(
            "gh pr comment 1 --body \"$(cat <<'EOF'\nGenerated with ChatGPT\nEOF\n)\"",
            "agent attribution",
        )

    def test_confirmation_allows_flagged_wording(self) -> None:
        self.say("post the reply")
        command = "gh issue comment 1 --body 'Tested with Claude Code 2.2 on NixOS.'"
        self.assert_denied(command, "prose rules")
        self.say("yes, keep that wording")
        self.assert_allowed(command)


if __name__ == "__main__":
    unittest.main()
