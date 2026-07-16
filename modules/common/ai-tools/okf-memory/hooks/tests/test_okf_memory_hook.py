from __future__ import annotations

import json
import os
import subprocess
import tempfile
import unittest
from pathlib import Path

HOOK = Path(__file__).parents[1] / "okf_memory_hook.py"
EXPECTED_START_NUDGE = """[okf-memory] Prior durable memory may apply. Read only relevant project or user OKF scope when this task depends on prior work, saved decisions, recurring issues, or preferences."""


class OkfMemoryHookTests(unittest.TestCase):
    def run_hook(
        self,
        root: Path,
        provider: str,
        event: str,
        payload: dict[str, object],
        *,
        threshold: int = 2,
        include_subagents: bool = False,
    ) -> dict[str, object] | str:
        environment = os.environ.copy()
        environment.update(
            HOME=str(root / "home"),
            XDG_DATA_HOME=str(root / "data"),
            XDG_RUNTIME_DIR=str(root / "run"),
            OKF_MEMORY_TOOL_THRESHOLD=str(threshold),
        )
        if include_subagents:
            environment["OKF_MEMORY_INCLUDE_SUBAGENTS"] = "1"
        (root / "run").mkdir(exist_ok=True)
        result = subprocess.run(
            ["python3", str(HOOK), provider, event],
            input=json.dumps(payload),
            text=True,
            capture_output=True,
            check=True,
            env=environment,
            cwd=root,
        )
        output = result.stdout.strip()
        try:
            return json.loads(output) if output else {}
        except json.JSONDecodeError:
            return output

    @staticmethod
    def append(transcript: Path, *records: dict[str, object]) -> None:
        with transcript.open("a", encoding="utf-8") as handle:
            for record in records:
                handle.write(json.dumps(record) + "\n")

    @staticmethod
    def claude_user(prompt: str, uuid: str = "user-1") -> dict[str, object]:
        return {
            "type": "user",
            "uuid": uuid,
            "message": {"role": "user", "content": prompt},
        }

    @staticmethod
    def claude_call(
        call_id: str, name: str = "Read", tool_input: object | None = None
    ) -> dict[str, object]:
        return {
            "type": "assistant",
            "message": {
                "role": "assistant",
                "content": [
                    {
                        "type": "tool_use",
                        "id": call_id,
                        "name": name,
                        "input": tool_input or {},
                    }
                ],
            },
        }

    @staticmethod
    def claude_result(call_id: str, *, failed: bool = False) -> dict[str, object]:
        return {
            "type": "user",
            "message": {
                "role": "user",
                "content": [
                    {
                        "type": "tool_result",
                        "tool_use_id": call_id,
                        "is_error": failed,
                        "content": "failed" if failed else "ok",
                    }
                ],
            },
        }

    def test_claude_session_start_emits_no_memory_context(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            bundle = root / ".okf"
            bundle.mkdir()
            (bundle / "MEMORY.local.md").write_text(
                "---\ntype: memory\n---\n\nProject summary.\n", encoding="utf-8"
            )
            (bundle / "index.md").write_text("# Project index\n", encoding="utf-8")
            output = self.run_hook(
                root,
                "claude",
                "session-start",
                {
                    "session_id": "one",
                    "cwd": str(root),
                    "hook_event_name": "SessionStart",
                },
            )
            self.assertEqual(output, {})
            self.assertTrue((root / "data" / "okf" / "index.md").exists())

    def test_codex_session_start_emits_small_memory_nudge(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            output = self.run_hook(
                root,
                "codex",
                "session-start",
                {
                    "session_id": "main",
                    "cwd": str(root),
                    "hook_event_name": "SessionStart",
                },
            )
            hook_output = output["hookSpecificOutput"]
            self.assertEqual(hook_output["hookEventName"], "SessionStart")
            self.assertEqual(hook_output["additionalContext"], EXPECTED_START_NUDGE)

    def test_codex_subagent_payload_skips_all_hooks(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            payload = {
                "session_id": "worker",
                "cwd": str(root),
                "source": {
                    "subagent": {
                        "thread_spawn": {
                            "parent_thread_id": "parent",
                            "agent_role": "fact-finder",
                        }
                    }
                },
                "prompt": "Remember this decision",
            }
            for event in ("session-start", "user-prompt", "stop"):
                self.assertEqual(self.run_hook(root, "codex", event, payload), {})
            self.assertFalse((root / "data" / "okf").exists())

    def test_codex_subagent_transcript_skips_hooks(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            transcript = root / "codex.jsonl"
            self.append(
                transcript,
                {
                    "type": "session_meta",
                    "payload": {
                        "source": {
                            "subagent": {
                                "thread_spawn": {
                                    "parent_thread_id": "parent",
                                    "agent_role": "test-runner",
                                }
                            }
                        }
                    },
                },
            )
            payload = {
                "session_id": "worker-transcript",
                "cwd": str(root),
                "transcript_path": str(transcript),
                "prompt": "Remember this decision",
            }
            self.assertEqual(self.run_hook(root, "codex", "user-prompt", payload), {})
            self.assertEqual(self.run_hook(root, "codex", "stop", payload), {})
            self.assertFalse((root / "data" / "okf").exists())

    def test_codex_subagent_override_restores_hook(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            output = self.run_hook(
                root,
                "codex",
                "session-start",
                {
                    "session_id": "worker-override",
                    "cwd": str(root),
                    "source": {"subagent": {"thread_spawn": {}}},
                },
                include_subagents=True,
            )
            self.assertEqual(
                output["hookSpecificOutput"]["additionalContext"],
                EXPECTED_START_NUDGE,
            )

    def test_routine_user_turn_emits_no_context(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            payload = {"session_id": "turn", "cwd": str(root)}
            output = self.run_hook(
                root,
                "codex",
                "user-prompt",
                payload | {"prompt": "Investigate this"},
            )
            self.assertEqual(output, {})

    def test_explicit_memory_intent_blocks_stop_once(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            payload = {"session_id": "explicit", "cwd": str(root)}
            output = self.run_hook(
                root,
                "codex",
                "user-prompt",
                payload | {"prompt": "Please remember this for the future"},
            )
            self.assertEqual(output, {})
            self.assertEqual(
                self.run_hook(root, "codex", "stop", payload)["decision"], "block"
            )
            self.assertEqual(self.run_hook(root, "codex", "stop", payload), {})

    def test_substantial_claude_work_gets_end_checkpoint(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            transcript = root / "claude.jsonl"
            transcript.touch()
            payload = {
                "session_id": "substantial",
                "cwd": str(root),
                "transcript_path": str(transcript),
            }
            self.append(transcript, self.claude_user("Investigate this"))
            self.run_hook(root, "claude", "user-prompt", payload)
            self.append(
                transcript,
                self.claude_call("call-1"),
                self.claude_result("call-1"),
                self.claude_call("call-2"),
                self.claude_result("call-2"),
            )
            stop = self.run_hook(root, "claude", "stop", payload)
            self.assertEqual(stop["decision"], "block")

    def test_small_turn_does_not_checkpoint(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            transcript = root / "claude.jsonl"
            transcript.touch()
            payload = {
                "session_id": "small",
                "cwd": str(root),
                "transcript_path": str(transcript),
            }
            self.run_hook(
                root,
                "claude",
                "user-prompt",
                payload | {"prompt": "Quick question"},
            )
            self.append(transcript, self.claude_call("only-call"))
            self.assertEqual(self.run_hook(root, "claude", "stop", payload), {})

    def test_successful_claude_okf_write_satisfies_checkpoint(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            transcript = root / "claude.jsonl"
            transcript.touch()
            payload = {
                "session_id": "write",
                "cwd": str(root),
                "transcript_path": str(transcript),
            }
            self.run_hook(
                root,
                "claude",
                "user-prompt",
                payload | {"prompt": "Remember that I prefer flakes"},
            )
            memory = root / "data" / "okf" / "MEMORY.local.md"
            memory.write_text(
                memory.read_text(encoding="utf-8") + "Durable preference.\n",
                encoding="utf-8",
            )
            self.append(
                transcript,
                self.claude_call(
                    "write-1", "Write", {"file_path": str(memory), "content": "x"}
                ),
                self.claude_result("write-1"),
            )
            self.assertEqual(self.run_hook(root, "claude", "stop", payload), {})

    def test_failed_claude_write_is_not_receipt(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            transcript = root / "claude.jsonl"
            transcript.touch()
            payload = {
                "session_id": "failed-write",
                "cwd": str(root),
                "transcript_path": str(transcript),
            }
            self.run_hook(
                root,
                "claude",
                "user-prompt",
                payload | {"prompt": "Remember that I prefer flakes"},
            )
            memory = root / "data" / "okf" / "MEMORY.local.md"
            memory.write_text(
                memory.read_text(encoding="utf-8") + "External change.\n",
                encoding="utf-8",
            )
            self.append(
                transcript,
                self.claude_call("write-1", "Write", {"file_path": str(memory)}),
                self.claude_result("write-1", failed=True),
            )
            stop = self.run_hook(root, "claude", "stop", payload)
            self.assertEqual(stop["decision"], "block")

    def test_read_only_okf_mention_is_not_receipt(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            transcript = root / "claude.jsonl"
            transcript.touch()
            payload = {
                "session_id": "read-only",
                "cwd": str(root),
                "transcript_path": str(transcript),
            }
            self.run_hook(
                root,
                "claude",
                "user-prompt",
                payload | {"prompt": "Remember that I prefer flakes"},
            )
            memory = root / "data" / "okf" / "MEMORY.local.md"
            memory.write_text(
                memory.read_text(encoding="utf-8") + "Other session.\n",
                encoding="utf-8",
            )
            self.append(
                transcript,
                self.claude_call(
                    "read-1",
                    "Bash",
                    {"command": "rg -n '.okf/' AGENTS.md > /tmp/okf-hits"},
                ),
                self.claude_result("read-1"),
            )
            stop = self.run_hook(root, "claude", "stop", payload)
            self.assertEqual(stop["decision"], "block")

    def test_codex_successful_patch_receipt(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            transcript = root / "codex.jsonl"
            transcript.touch()
            payload = {
                "session_id": "codex-patch",
                "cwd": str(root),
                "transcript_path": str(transcript),
            }
            self.run_hook(
                root,
                "codex",
                "user-prompt",
                payload | {"prompt": "Remember this decision"},
            )
            concept = root / ".okf" / "concepts" / "decision.md"
            concept.parent.mkdir(parents=True)
            concept.write_text("---\ntype: decision\n---\n", encoding="utf-8")
            self.append(
                transcript,
                {
                    "type": "event_msg",
                    "payload": {
                        "type": "patch_apply_end",
                        "success": True,
                        "changes": {str(concept): {"kind": "add"}},
                    },
                },
            )
            self.assertEqual(self.run_hook(root, "codex", "stop", payload), {})

    def test_codex_failed_patch_receipt_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            transcript = root / "codex.jsonl"
            transcript.touch()
            payload = {
                "session_id": "codex-failed",
                "cwd": str(root),
                "transcript_path": str(transcript),
            }
            self.run_hook(
                root,
                "codex",
                "user-prompt",
                payload | {"prompt": "Remember this decision"},
            )
            concept = root / ".okf" / "concepts" / "decision.md"
            concept.parent.mkdir(parents=True)
            concept.write_text("changed", encoding="utf-8")
            self.append(
                transcript,
                {
                    "type": "event_msg",
                    "payload": {
                        "type": "patch_apply_end",
                        "success": False,
                        "changes": {str(concept): {"kind": "add"}},
                    },
                },
            )
            stop = self.run_hook(root, "codex", "stop", payload)
            self.assertEqual(stop["decision"], "block")

    def test_provider_injected_user_records_are_not_turn_boundaries(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            claude = root / "claude.jsonl"
            self.append(
                claude,
                {
                    "type": "user",
                    "uuid": "meta",
                    "isMeta": True,
                    "message": {
                        "role": "user",
                        "content": [{"type": "text", "text": "Remember this"}],
                    },
                },
                self.claude_user("Actual question", "actual"),
                self.claude_result("old-call"),
            )
            claude_output = self.run_hook(
                root,
                "claude",
                "user-prompt",
                {
                    "session_id": "meta",
                    "cwd": str(root),
                    "transcript_path": str(claude),
                },
            )
            self.assertEqual(claude_output, {})

            codex = root / "codex.jsonl"
            self.append(
                codex,
                {
                    "type": "response_item",
                    "payload": {
                        "type": "message",
                        "role": "user",
                        "content": "Remember injected policy",
                    },
                },
                {
                    "type": "event_msg",
                    "timestamp": "2026-07-11T00:00:00Z",
                    "payload": {"type": "user_message", "message": "Actual question"},
                },
            )
            codex_output = self.run_hook(
                root,
                "codex",
                "user-prompt",
                {
                    "session_id": "injected",
                    "cwd": str(root),
                    "transcript_path": str(codex),
                },
            )
            self.assertEqual(codex_output, {})

    def test_large_turn_and_rotated_transcript_are_scanned(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            transcript = root / "claude.jsonl"
            transcript.touch()
            payload = {
                "session_id": "rotation",
                "cwd": str(root),
                "transcript_path": str(transcript),
            }
            self.run_hook(
                root,
                "claude",
                "user-prompt",
                payload | {"prompt": "Remember this decision"},
            )
            replacement = root / "replacement.jsonl"
            replacement.write_text(
                json.dumps({"type": "noise", "content": "x" * 1_100_000}) + "\n",
                encoding="utf-8",
            )
            self.append(
                replacement,
                self.claude_call("call-1"),
                self.claude_call("call-2"),
            )
            replacement.replace(transcript)
            stop = self.run_hook(root, "claude", "stop", payload)
            self.assertEqual(stop["decision"], "block")

    def test_compaction_reinjection_preserves_current_turn(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            transcript = root / "claude.jsonl"
            transcript.touch()
            payload = {
                "session_id": "compact",
                "cwd": str(root),
                "transcript_path": str(transcript),
            }
            self.run_hook(
                root,
                "claude",
                "user-prompt",
                payload | {"prompt": "Remember this decision"},
            )
            self.append(
                transcript,
                self.claude_call("call-1"),
                self.claude_call("call-2"),
            )
            context = self.run_hook(
                root,
                "claude",
                "session-start",
                payload | {"source": "compact"},
            )
            self.assertEqual(context, {})
            stop = self.run_hook(root, "claude", "stop", payload)
            self.assertEqual(stop["decision"], "block")

    def test_antigravity_pre_invocation_stays_silent(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            transcript = root / "antigravity.jsonl"
            self.append(
                transcript,
                {
                    "step_index": 0,
                    "created_at": "2026-07-11T00:00:00Z",
                    "source": "USER_EXPLICIT",
                    "type": "USER_INPUT",
                    "content": "<USER_REQUEST>Investigate</USER_REQUEST>",
                },
            )
            payload = {
                "conversationId": "antigravity",
                "workspacePaths": [str(root)],
                "transcriptPath": str(transcript),
            }
            first = self.run_hook(root, "antigravity", "pre-invocation", payload)
            self.assertEqual(first, {"injectSteps": []})
            self.assertEqual(
                self.run_hook(root, "antigravity", "pre-invocation", payload),
                {"injectSteps": []},
            )
            self.append(
                transcript,
                {
                    "step_index": 2,
                    "created_at": "2026-07-11T00:01:00Z",
                    "source": "USER_EXPLICIT",
                    "type": "USER_INPUT",
                    "content": "<USER_REQUEST>Remember that I prefer flakes</USER_REQUEST>",
                },
            )
            second = self.run_hook(root, "antigravity", "pre-invocation", payload)
            self.assertEqual(second, {"injectSteps": []})
            self.assertEqual(
                self.run_hook(root, "antigravity", "stop", payload)["decision"],
                "continue",
            )

    def test_antigravity_write_receipt_satisfies_checkpoint(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            transcript = root / "antigravity.jsonl"
            self.append(
                transcript,
                {
                    "step_index": 0,
                    "created_at": "2026-07-11T00:00:00Z",
                    "source": "USER_EXPLICIT",
                    "type": "USER_INPUT",
                    "content": "<USER_REQUEST>Remember this preference</USER_REQUEST>",
                },
            )
            payload = {
                "conversationId": "antigravity-write",
                "workspacePaths": [str(root)],
                "transcriptPath": str(transcript),
            }
            self.run_hook(root, "antigravity", "pre-invocation", payload)
            memory = root / "data" / "okf" / "MEMORY.local.md"
            memory.write_text(
                memory.read_text(encoding="utf-8") + "Durable preference.\n",
                encoding="utf-8",
            )
            self.append(
                transcript,
                {
                    "step_index": 1,
                    "type": "PLANNER_RESPONSE",
                    "tool_calls": [
                        {
                            "name": "replace_file_content",
                            "args": {"TargetFile": str(memory)},
                        }
                    ],
                },
                {
                    "step_index": 2,
                    "type": "CODE_ACTION",
                    "content": f"Changes written to {memory}",
                },
            )
            self.assertEqual(
                self.run_hook(root, "antigravity", "stop", payload),
                {"decision": "stop"},
            )

    def test_previous_turn_write_does_not_satisfy_new_intent(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            transcript = root / "claude.jsonl"
            transcript.touch()
            payload = {
                "session_id": "new-turn",
                "cwd": str(root),
                "transcript_path": str(transcript),
            }
            self.run_hook(
                root,
                "claude",
                "user-prompt",
                payload | {"prompt": "Remember first preference"},
            )
            memory = root / "data" / "okf" / "MEMORY.local.md"
            memory.write_text(
                memory.read_text(encoding="utf-8") + "First preference.\n",
                encoding="utf-8",
            )
            self.append(
                transcript,
                self.claude_call("first-write", "Write", {"file_path": str(memory)}),
                self.claude_result("first-write"),
            )
            self.assertEqual(self.run_hook(root, "claude", "stop", payload), {})

            self.run_hook(
                root,
                "claude",
                "user-prompt",
                payload | {"prompt": "Remember that second preference"},
            )
            stop = self.run_hook(root, "claude", "stop", payload)
            self.assertEqual(stop["decision"], "block")

    def test_large_memory_file_is_not_injected(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            bundle = root / ".okf"
            bundle.mkdir()
            (bundle / "MEMORY.local.md").write_text(
                "---\ntype: memory\n---\n\n" + "x" * 20_000,
                encoding="utf-8",
            )
            output = self.run_hook(
                root,
                "claude",
                "session-start",
                {"session_id": "budget", "cwd": str(root)},
            )
            self.assertEqual(output, {})


if __name__ == "__main__":
    unittest.main()
