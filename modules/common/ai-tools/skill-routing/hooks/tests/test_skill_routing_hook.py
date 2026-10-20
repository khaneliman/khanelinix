from __future__ import annotations

import importlib.util
import io
import json
import subprocess
import unittest
from pathlib import Path

HOOK = Path(__file__).parents[1] / "skill_routing_hook.py"
SPEC = importlib.util.spec_from_file_location("skill_routing_hook", HOOK)
assert SPEC is not None and SPEC.loader is not None
skill_routing_hook = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(skill_routing_hook)


class SkillRoutingHookTests(unittest.TestCase):
    def test_review_reminder_is_advisory_and_keeps_delivery_boundary(self) -> None:
        result = subprocess.run(
            ["python3", str(HOOK), "claude", "user-prompt"],
            input=json.dumps(
                {
                    "session_id": "one",
                    "prompt": "Review https://github.com/example/project/pull/123",
                }
            ),
            text=True,
            capture_output=True,
            check=True,
        )
        output = json.loads(result.stdout)
        self.assertNotIn("decision", output)
        context = output["hookSpecificOutput"]
        self.assertEqual(context["hookEventName"], "UserPromptSubmit")
        self.assertNotIn("permissionDecision", context)
        for expected in (
            "github-toolkit",
            "premise-first",
            "pending review",
            "never a submitted review",
        ):
            self.assertIn(expected, context["additionalContext"])

    def test_narrow_checks_and_explicit_negation_do_not_suggest_review(self) -> None:
        for prompt in (
            "Check only whether CI passed for https://github.com/example/project/pull/123. Do not review the code.",
            "Check whether https://github.com/example/project/pull/123 has a merge conflict.",
            "Do not review https://github.com/example/project/pull/123; just summarize the title.",
            "Implement https://github.com/acme/code-review/pull/123",
        ):
            with self.subTest(prompt=prompt):
                self.assertIsNone(skill_routing_hook.suggested_skill(prompt))

    def test_review_url_delimiters_are_supported(self) -> None:
        for prompt in (
            "Review <https://github.com/example/project/pull/123>",
            'Review "https://github.com/example/project/pull/123"',
            "Review [this PR](https://github.com/example/project/pull/123)",
            "Review `https://github.com/example/project/pull/123`",
        ):
            with self.subTest(prompt=prompt):
                self.assertEqual(
                    skill_routing_hook.suggested_skill(prompt), "github-toolkit"
                )

    def test_unrelated_or_invalid_urls_are_ignored(self) -> None:
        for prompt in (
            "Review https://github.com/example/project/pull/123-invalid",
            "Review https://github.com/acme/repo?next=/pull/123",
            "Review https://github.com/acme/repo#next=/pull/123",
            "Review https://example.com/acme/repo/pull/123",
            "Review this local change",
        ):
            with self.subTest(prompt=prompt):
                self.assertIsNone(skill_routing_hook.suggested_skill(prompt))

    def test_tool_and_state_events_cannot_block_even_with_old_pending_route(
        self,
    ) -> None:
        for event in (
            "pre-tool",
            "post-tool",
            "post-compact",
            "session-end",
            "prompt-expansion",
        ):
            with self.subTest(event=event):
                self.assertIsNone(
                    skill_routing_hook.handle(
                        "claude",
                        event,
                        {
                            "session_id": "one",
                            "pending_skill": "github-toolkit",
                            "tool_name": "Bash",
                            "prompt": "Review https://github.com/example/project/pull/123",
                        },
                    )
                )

    def test_background_notifications_and_subagents_are_ignored(self) -> None:
        prompt = "Review https://github.com/example/project/pull/123"
        for payload in (
            {"prompt": "[SYSTEM NOTIFICATION] " + prompt},
            {"prompt": "<task-notification>" + prompt + "</task-notification>"},
            {"prompt": prompt, "agent_id": "child"},
        ):
            with self.subTest(payload=payload):
                self.assertIsNone(
                    skill_routing_hook.handle("claude", "user-prompt", payload)
                )

    def test_invalid_input_and_unknown_provider_are_silent(self) -> None:
        self.assertIsNone(skill_routing_hook.load_payload(io.StringIO("")))
        self.assertIsNone(skill_routing_hook.load_payload(io.StringIO("[]")))
        self.assertIsNone(
            skill_routing_hook.handle("other", "user-prompt", {"prompt": "Review"})
        )
        result = subprocess.run(
            ["python3", str(HOOK), "claude", "user-prompt"],
            input="not-json",
            text=True,
            capture_output=True,
            check=True,
        )
        self.assertEqual(result.stdout, "")

    def test_claude_wiring_runs_only_at_user_prompt(self) -> None:
        module = (
            Path(__file__).parents[5]
            / "home/programs/terminal/tools/claude-code/hooks/skill-routing.nix"
        ).read_text(encoding="utf-8")
        self.assertIn("UserPromptSubmit", module)
        for event in (
            "PreToolUse",
            "PostToolUse",
            "UserPromptExpansion",
            "PostCompact",
            "SessionEnd",
        ):
            self.assertNotIn(event, module)


if __name__ == "__main__":
    unittest.main()
