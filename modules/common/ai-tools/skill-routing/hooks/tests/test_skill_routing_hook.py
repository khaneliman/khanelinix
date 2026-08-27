from __future__ import annotations

import importlib.util
import io
import subprocess
import tempfile
import threading
import unittest
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

HOOK = Path(__file__).parents[1] / "skill_routing_hook.py"
BASE_MD = Path(__file__).parents[3] / "base.md"
SPEC = importlib.util.spec_from_file_location("skill_routing_hook", HOOK)
assert SPEC is not None and SPEC.loader is not None
skill_routing_hook = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(skill_routing_hook)


class SkillRoutingHookTests(unittest.TestCase):
    def test_shared_context_requires_owner_invocation_before_task_work(self) -> None:
        text = " ".join(BASE_MD.read_text(encoding="utf-8").split())
        self.assertIn(
            "Every new or materially changed parent task requires a skill decision",
            text,
        )
        self.assertIn(
            "Before task-specific tools or a substantive answer, invoke the closest "
            "matching owner skill",
            text,
        )
        self.assertIn("Expect one owner skill for most tasks", text)
        self.assertIn("Do not load unrelated skills to reach a quota", text)
        self.assertIn("If no visible skill fits, continue without inventing one", text)
        self.assertIn(
            "Child workers follow the skill or tool lane in their packet", text
        )

    def test_github_pr_review_blocks_task_tools_until_skill_succeeds(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            prompt = {
                "session_id": "one",
                "prompt": "Please review https://github.com/example/project/pull/123",
            }
            self.assertIsNone(
                skill_routing_hook.handle("claude", "user-prompt", prompt, root)
            )

            blocked = skill_routing_hook.handle(
                "claude",
                "pre-tool",
                {"session_id": "one", "tool_name": "Bash", "tool_input": {}},
                root,
            )
            assert blocked is not None
            decision = blocked["hookSpecificOutput"]
            self.assertEqual(decision["permissionDecision"], "deny")
            self.assertIn("github-toolkit", decision["permissionDecisionReason"])

            skill_call = {
                "session_id": "one",
                "tool_name": "Skill",
                "tool_input": {"skill": "github-toolkit"},
            }
            self.assertIsNone(
                skill_routing_hook.handle("claude", "pre-tool", skill_call, root)
            )
            self.assertIsNone(
                skill_routing_hook.handle("claude", "post-tool", skill_call, root)
            )
            self.assertIsNone(
                skill_routing_hook.handle(
                    "claude",
                    "pre-tool",
                    {"session_id": "one", "tool_name": "Bash", "tool_input": {}},
                    root,
                )
            )

            skill_routing_hook.handle(
                "claude",
                "user-prompt",
                {
                    "session_id": "one",
                    "prompt": (
                        "Check the review status for "
                        "https://github.com/example/project/pull/123"
                    ),
                },
                root,
            )
            self.assertIsNone(
                skill_routing_hook.handle(
                    "claude",
                    "pre-tool",
                    {"session_id": "one", "tool_name": "Bash", "tool_input": {}},
                    root,
                )
            )

    def test_exact_corpus_prompt_arms_despite_posting_negation(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            prompt = {
                "session_id": "one",
                "prompt": (
                    "Review https://github.com/example/project/pull/123 and report "
                    "actionable findings. Do not post a review or change code."
                ),
            }
            skill_routing_hook.handle("claude", "user-prompt", prompt, root)
            blocked = skill_routing_hook.handle(
                "claude",
                "pre-tool",
                {"session_id": "one", "tool_name": "Bash", "tool_input": {}},
                root,
            )
            self.assertIsNotNone(blocked)

    def test_common_url_delimiters_arm(self) -> None:
        prompts = (
            "Review <https://github.com/example/project/pull/123>",
            'Review "https://github.com/example/project/pull/123"',
            "Review [this PR](https://github.com/example/project/pull/123)",
            "Review `https://github.com/example/project/pull/123`",
        )
        for index, prompt in enumerate(prompts):
            with (
                self.subTest(prompt=prompt),
                tempfile.TemporaryDirectory() as temporary,
            ):
                root = Path(temporary)
                skill_routing_hook.handle(
                    "claude",
                    "user-prompt",
                    {"session_id": f"session-{index}", "prompt": prompt},
                    root,
                )
                blocked = skill_routing_hook.handle(
                    "claude",
                    "pre-tool",
                    {
                        "session_id": f"session-{index}",
                        "tool_name": "Bash",
                        "tool_input": {},
                    },
                    root,
                )
                self.assertIsNotNone(blocked)

    def test_direct_skill_expansion_satisfies_route(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            skill_routing_hook.handle(
                "claude",
                "user-prompt",
                {
                    "session_id": "one",
                    "prompt": (
                        "/github-toolkit Review "
                        "https://github.com/example/project/pull/123"
                    ),
                },
                root,
            )
            skill_routing_hook.handle(
                "claude",
                "prompt-expansion",
                {
                    "session_id": "one",
                    "command_name": "github-toolkit",
                },
                root,
            )
            self.assertIsNone(
                skill_routing_hook.handle(
                    "claude",
                    "pre-tool",
                    {"session_id": "one", "tool_name": "Bash", "tool_input": {}},
                    root,
                )
            )

    def test_wrong_skill_does_not_satisfy_route(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            prompt = {
                "session_id": "one",
                "prompt": "Audit https://github.com/example/project/pull/123",
            }
            skill_routing_hook.handle("claude", "user-prompt", prompt, root)
            skill_routing_hook.handle(
                "claude",
                "post-tool",
                {
                    "session_id": "one",
                    "tool_name": "Skill",
                    "tool_input": {"skill": "code-review"},
                },
                root,
            )
            blocked = skill_routing_hook.handle(
                "claude",
                "pre-tool",
                {"session_id": "one", "tool_name": "Read", "tool_input": {}},
                root,
            )
            self.assertIsNotNone(blocked)

    def test_unmatched_followup_clears_stale_route(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            skill_routing_hook.handle(
                "claude",
                "user-prompt",
                {
                    "session_id": "one",
                    "prompt": "Review https://github.com/example/project/pull/123",
                },
                root,
            )
            skill_routing_hook.handle(
                "claude",
                "user-prompt",
                {"session_id": "one", "prompt": "What is the status?"},
                root,
            )
            self.assertIsNone(
                skill_routing_hook.handle(
                    "claude",
                    "pre-tool",
                    {"session_id": "one", "tool_name": "Bash", "tool_input": {}},
                    root,
                )
            )

    def test_negative_intent_and_invalid_urls_do_not_arm(self) -> None:
        prompts = (
            "Do not review https://github.com/example/project/pull/123",
            "Implement https://github.com/acme/code-review/pull/123",
            "Check https://github.com/example/project/pull/123-invalid",
            "Check https://github.com/acme/repo?next=/pull/123",
            "Review https://github.com/acme/repo#next=/pull/123",
        )
        for index, prompt in enumerate(prompts):
            with (
                self.subTest(prompt=prompt),
                tempfile.TemporaryDirectory() as temporary,
            ):
                root = Path(temporary)
                skill_routing_hook.handle(
                    "claude",
                    "user-prompt",
                    {"session_id": f"session-{index}", "prompt": prompt},
                    root,
                )
                self.assertIsNone(
                    skill_routing_hook.handle(
                        "claude",
                        "pre-tool",
                        {
                            "session_id": f"session-{index}",
                            "tool_name": "Bash",
                            "tool_input": {},
                        },
                        root,
                    )
                )

    def test_post_compact_invalidates_loaded_skills_and_rearms(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            payload = {"session_id": "one"}
            path = skill_routing_hook.state_path(payload, root)
            assert path is not None
            with skill_routing_hook.locked_state(path):
                skill_routing_hook.write_state(path, {"github-toolkit"}, None)
            skill_routing_hook.handle("claude", "post-compact", payload, root)
            skill_routing_hook.handle(
                "claude",
                "user-prompt",
                {
                    "session_id": "one",
                    "prompt": "Review https://github.com/example/project/pull/123",
                },
                root,
            )
            blocked = skill_routing_hook.handle(
                "claude",
                "pre-tool",
                {"session_id": "one", "tool_name": "Bash", "tool_input": {}},
                root,
            )
            self.assertIsNotNone(blocked)

    def test_concurrent_skill_completions_preserve_both_updates(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            payload = {"session_id": "one"}
            path = skill_routing_hook.state_path(payload, root)
            assert path is not None
            with skill_routing_hook.locked_state(path):
                skill_routing_hook.write_state(path, set(), "github-toolkit")
            barrier = threading.Barrier(2)

            def complete(skill: str) -> None:
                barrier.wait()
                skill_routing_hook.handle(
                    "claude",
                    "post-tool",
                    {
                        "session_id": "one",
                        "tool_name": "Skill",
                        "tool_input": {"skill": skill},
                    },
                    root,
                )

            with ThreadPoolExecutor(max_workers=2) as executor:
                futures = [
                    executor.submit(complete, skill)
                    for skill in ("github-toolkit", "technical-writing")
                ]
                for future in futures:
                    future.result()

            with skill_routing_hook.locked_state(path):
                loaded, pending = skill_routing_hook.read_state(path)
            self.assertEqual(loaded, {"github-toolkit", "technical-writing"})
            self.assertIsNone(pending)

    def test_session_end_removes_loaded_state(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            payload = {"session_id": "one"}
            path = skill_routing_hook.state_path(payload, root)
            assert path is not None
            with skill_routing_hook.locked_state(path):
                skill_routing_hook.write_state(path, {"github-toolkit"}, None)
            self.assertTrue(path.exists())
            skill_routing_hook.handle("claude", "session-end", payload, root)
            self.assertFalse(path.exists())

    def test_symlink_state_root_blocks_matching_prompt(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            base = Path(temporary)
            target = base / "target"
            target.mkdir()
            root = base / "state"
            root.symlink_to(target, target_is_directory=True)
            payload = {
                "session_id": "one",
                "prompt": "Review https://github.com/example/project/pull/123",
            }
            with self.assertRaises(OSError):
                skill_routing_hook.handle("claude", "user-prompt", payload, root)
            blocked = skill_routing_hook.state_failure("user-prompt", payload)
            self.assertEqual(blocked["decision"], "block")

    def test_subagent_tools_are_not_gated(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            output = skill_routing_hook.handle(
                "claude",
                "pre-tool",
                {
                    "session_id": "one",
                    "agent_id": "child-one",
                    "tool_name": "Bash",
                    "tool_input": {},
                },
                root,
            )
            self.assertIsNone(output)

    def test_unknown_provider_or_event_is_silent(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            payload = {"session_id": "one"}
            root = Path(temporary)
            self.assertIsNone(
                skill_routing_hook.handle("other", "user-prompt", payload, root)
            )
            self.assertIsNone(
                skill_routing_hook.handle("claude", "other", payload, root)
            )

    def test_empty_or_invalid_input_fails_open(self) -> None:
        self.assertIsNone(skill_routing_hook.load_payload(io.StringIO("")))
        self.assertIsNone(skill_routing_hook.load_payload(io.StringIO("[]")))

        result = subprocess.run(
            ["python3", str(HOOK), "claude", "user-prompt"],
            input="not-json",
            text=True,
            capture_output=True,
            check=True,
        )
        self.assertEqual(result.stdout, "")

    def test_claude_nix_wiring_uses_state_and_tool_events(self) -> None:
        module = (
            Path(__file__).parents[5]
            / "home/programs/terminal/tools/claude-code/hooks/skill-routing.nix"
        ).read_text(encoding="utf-8")
        self.assertIn("UserPromptSubmit", module)
        self.assertIn("UserPromptExpansion", module)
        self.assertIn("PreToolUse", module)
        self.assertIn("PostToolUse", module)
        self.assertIn("PostCompact", module)
        self.assertIn("SessionEnd", module)
        self.assertIn('matcher = "*";', module)
        self.assertIn('matcher = "github-toolkit";', module)
        self.assertIn('matcher = "Skill";', module)


if __name__ == "__main__":
    unittest.main()
