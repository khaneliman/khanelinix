from __future__ import annotations

import json
import subprocess
import sys
import unittest

from support import HOOK, GateCase, bash, grants, hook


class ProviderTests(GateCase):
    def test_codex_delegated_prompts_do_not_grant(self) -> None:
        for source in (
            "exec",
            {"subagent": {"thread_spawn": {"agent_role": "implementer"}}},
        ):
            with self.subTest(source=source):
                transcript = self.work / "rollout.jsonl"
                transcript.write_text(
                    json.dumps({"type": "session_meta", "payload": {"source": source}})
                    + "\n"
                )
                self.say(
                    "Goal: finalize PR #9864, push the branch, and mark it ready.",
                    provider="codex",
                    transcript_path=str(transcript),
                    session="codex-one",
                )
                output = hook.handle(
                    "codex",
                    "pre-tool",
                    bash(
                        "git push origin fix", session="codex-one", cwd=str(self.work)
                    ),
                    self.root,
                )
                self.assertIsNotNone(output)

    def test_codex_delegated_denial_names_the_launcher(self) -> None:
        transcript = self.work / "rollout.jsonl"
        transcript.write_text(
            json.dumps({"type": "session_meta", "payload": {"source": "exec"}}) + "\n"
        )
        output = hook.handle(
            "codex",
            "pre-tool",
            bash(
                "git push origin fix",
                session="codex-exec",
                cwd=str(self.work),
                transcript_path=str(transcript),
            ),
            self.root,
        )
        assert output is not None
        reason = output["hookSpecificOutput"]["permissionDecisionReason"]
        self.assertIn(grants.GRANTS_ENV, reason)

    def test_codex_subagent_source_in_payload_does_not_grant(self) -> None:
        self.say(
            "push the branch",
            provider="codex",
            session="codex-sub",
            source={"subagent": {"thread_spawn": {"agent_role": "worker"}}},
        )
        output = hook.handle(
            "codex",
            "pre-tool",
            bash("git push origin fix", session="codex-sub", cwd=str(self.work)),
            self.root,
        )
        self.assertIsNotNone(output)

    def test_codex_interactive_prompts_grant(self) -> None:
        transcript = self.work / "rollout.jsonl"
        transcript.write_text(
            json.dumps({"type": "session_meta", "payload": {"source": "vscode"}}) + "\n"
        )
        self.say(
            "push it",
            provider="codex",
            transcript_path=str(transcript),
            session="codex-two",
        )
        output = hook.handle(
            "codex",
            "pre-tool",
            bash("git push origin fix", session="codex-two", cwd=str(self.work)),
            self.root,
        )
        self.assertIsNone(output)

    def test_session_end_clears_grants(self) -> None:
        self.say("for this session you may push")
        hook.handle("claude", "session-end", {"session_id": "one"}, self.root)
        self.assert_denied("git push origin fix", "push")

    def test_non_bash_tools_and_unknown_events_are_silent(self) -> None:
        self.assertIsNone(
            hook.handle(
                "claude",
                "pre-tool",
                {"session_id": "one", "tool_name": "Read", "tool_input": {}},
                self.root,
            )
        )
        self.assertIsNone(hook.handle("other", "pre-tool", bash("git push"), self.root))
        self.assertIsNone(hook.handle("claude", "other", bash("git push"), self.root))

    def test_subprocess_emits_valid_deny_json(self) -> None:
        result = subprocess.run(
            [sys.executable, "-B", str(HOOK), "claude", "pre-tool"],
            input=json.dumps(
                bash("gh pr merge 3 --squash", session="fresh", cwd=str(self.work))
            ),
            text=True,
            capture_output=True,
            check=True,
            env={
                "XDG_RUNTIME_DIR": str(self.root),
                "XDG_STATE_HOME": str(self.work),
                "PATH": "/usr/bin:/bin",
            },
        )
        decision = json.loads(result.stdout)["hookSpecificOutput"]
        self.assertEqual(decision["permissionDecision"], "deny")

    def test_invalid_input_fails_open(self) -> None:
        result = subprocess.run(
            [sys.executable, "-B", str(HOOK), "claude", "pre-tool"],
            input="not-json",
            text=True,
            capture_output=True,
            check=True,
        )
        self.assertEqual(result.stdout, "")

    def test_internal_errors_deny_recognizable_writes(self) -> None:
        output = hook.failure(
            "pre-tool", bash("gh pr comment 1 --body hi"), RuntimeError("boom")
        )
        self.assertIsNotNone(output)
        self.assertIsNone(
            hook.failure("pre-tool", bash("ls -la"), RuntimeError("boom"))
        )
        for command in (
            "nixpkgs-review pr 1 --post-result",
            "gh release create v1",
            "gh api -X POST repos/o/r/issues/1/comments -f body=x",
            "nh os switch .",
        ):
            with self.subTest(command=command):
                self.assertIsNotNone(
                    hook.failure("pre-tool", bash(command), RuntimeError("boom"))
                )


if __name__ == "__main__":
    unittest.main()
