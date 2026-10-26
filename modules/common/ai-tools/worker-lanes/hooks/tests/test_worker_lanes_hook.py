from __future__ import annotations

import importlib.util
import json
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from typing import Any
from unittest import mock

HOOK = Path(__file__).parents[1] / "worker_lanes_hook.py"
SPEC = importlib.util.spec_from_file_location("worker_lanes_hook", HOOK)
assert SPEC is not None and SPEC.loader is not None
worker_lanes_hook = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = worker_lanes_hook
SPEC.loader.exec_module(worker_lanes_hook)


def launch(agent_id: str, description: str) -> dict[str, Any]:
    return {
        "session_id": "run",
        "tool_name": "Agent",
        "tool_input": {"description": description, "run_in_background": True},
        "tool_response": {
            "status": "async_launched",
            "agentId": agent_id,
            "isAsync": True,
        },
    }


def notification(agent_id: str, summary: str = "finished") -> dict[str, Any]:
    return {
        "session_id": "run",
        "prompt": f"<task-notification>\n<task-id>{agent_id}</task-id>\n"
        + f"<status>completed</status>\n<summary>Agent {summary}</summary>\n"
        + "</task-notification>",
    }


def stop(*running: tuple[str, str], **extra: Any) -> dict[str, Any]:
    tasks = [
        {"id": task_id, "type": "subagent", "status": "running", "description": text}
        for task_id, text in running
    ]
    tasks.append(
        {"id": "b1", "type": "shell", "status": "running", "description": "tail"}
    )
    return {"session_id": "run", "background_tasks": tasks, **extra}


def tool(name: str = "Read") -> dict[str, Any]:
    return {
        "session_id": "run",
        "tool_name": name,
        "tool_input": {},
        "tool_response": {},
    }


def context(output: dict[str, Any] | None) -> str:
    assert output is not None
    return output["hookSpecificOutput"]["additionalContext"]


class WorkerLanesHookTests(unittest.TestCase):
    runtime: Path

    def setUp(self) -> None:
        runtime = tempfile.TemporaryDirectory()
        self.addCleanup(runtime.cleanup)
        self.runtime = Path(runtime.name)
        patcher = mock.patch.dict(os.environ, {"XDG_RUNTIME_DIR": runtime.name})
        patcher.start()
        self.addCleanup(patcher.stop)

    def handle(self, event: str, payload: dict[str, Any]) -> dict[str, Any] | None:
        return worker_lanes_hook.handle("claude", event, payload)

    def start_two_lanes(self) -> None:
        self.handle("post-tool", launch("a1", "Port parser module"))
        self.handle("post-tool", launch("a2", "Port lexer module"))

    def test_sessions_without_background_workers_leave_no_state(self) -> None:
        self.handle("user-prompt", {"session_id": "run", "prompt": "/burn the backlog"})
        self.handle("post-tool", tool("Bash"))
        self.handle("stop", stop())
        self.assertFalse((self.runtime / "worker-lanes").exists())

    def test_foreground_agents_leave_no_state(self) -> None:
        foreground = launch("a1", "Quick check")
        foreground["tool_response"]["status"] = "completed"
        self.handle("post-tool", foreground)
        self.assertFalse(worker_lanes_hook.state_path("run").exists())

    def test_a_single_background_worker_is_not_a_fan_out_run(self) -> None:
        self.handle("post-tool", launch("a1", "Explore callers"))
        for _ in range(worker_lanes_hook.DRIFT_STEPS + 1):
            self.assertIsNone(self.handle("post-tool", tool()))
        self.assertIsNone(self.handle("user-prompt", notification("a1")))
        self.assertIsNone(self.handle("stop", stop()))

    def test_finish_reminder_names_lanes_without_native_ids(self) -> None:
        self.start_two_lanes()
        reminder = context(self.handle("user-prompt", notification("a1")))
        self.assertIn("Finished: Port parser module.", reminder)
        self.assertIn("Still in flight: Port lexer module.", reminder)
        self.assertNotIn("a2", reminder)

    def test_interim_and_unknown_notifications_do_not_finish_lanes(self) -> None:
        self.start_two_lanes()
        interim = notification("a1", "is waiting on its own background work")
        self.assertIsNone(self.handle("user-prompt", interim))
        self.assertIsNone(self.handle("user-prompt", notification("b1")))
        self.assertIn(
            "Port parser module",
            context(self.handle("user-prompt", notification("a1"))),
        )

    def test_stop_check_fires_once_after_every_lane_finishes(self) -> None:
        self.start_two_lanes()
        self.handle("user-prompt", notification("a1"))
        self.assertIsNone(self.handle("stop", stop(("a2", "Port lexer module"))))
        self.handle("user-prompt", notification("a2"))
        self.assertIsNone(self.handle("stop", stop(stop_hook_active=True)))
        output = self.handle("stop", stop())
        assert output is not None
        self.assertNotIn("decision", output)
        self.assertEqual(output["hookSpecificOutput"]["hookEventName"], "Stop")
        self.assertIn("No worker lane is in flight", context(output))
        self.assertIsNone(self.handle("stop", stop()))

    def test_stop_uses_harness_task_list_over_missed_notifications(self) -> None:
        self.start_two_lanes()
        # Neither notification reached this hook; the harness list wins.
        self.assertIsNone(self.handle("stop", stop(("a2", "Port lexer module"))))
        self.assertIn(
            "No worker lane is in flight", context(self.handle("stop", stop()))
        )
        self.handle("post-tool", launch("a3", "Port emitter module"))
        self.assertIsNone(self.handle("user-prompt", notification("a1")))

    def test_dispatch_after_a_finish_disarms_the_stop_check(self) -> None:
        self.start_two_lanes()
        self.handle("user-prompt", notification("a1"))
        self.handle("user-prompt", notification("a2"))
        self.handle("post-tool", launch("a3", "Port emitter module"))
        self.handle("user-prompt", notification("a3"))
        self.assertIsNotNone(self.handle("stop", stop()))
        self.handle("post-tool", launch("a4", "Port runtime module"))
        self.assertIsNone(self.handle("stop", stop(("a4", "Port runtime module"))))

    def test_drift_reminder_fires_once_while_slots_sit_empty(self) -> None:
        self.start_two_lanes()
        for _ in range(worker_lanes_hook.DRIFT_STEPS):
            self.assertIsNone(self.handle("post-tool", tool()))
        self.handle("user-prompt", notification("a1"))
        for _ in range(worker_lanes_hook.DRIFT_STEPS - 1):
            self.assertIsNone(self.handle("post-tool", tool()))
        drift = context(self.handle("post-tool", tool()))
        self.assertIn("1 of 2 worker lanes are in flight", drift)
        for _ in range(worker_lanes_hook.DRIFT_STEPS):
            self.assertIsNone(self.handle("post-tool", tool()))

    def test_t3_tasks_finish_by_wake_message_or_status_read(self) -> None:
        self.handle(
            "post-tool",
            {
                "session_id": "run",
                "tool_name": "mcp__t3-code__delegate_task",
                "tool_input": {"task": "Review the diff", "title": "Codex review"},
                "tool_response": [
                    {
                        "type": "text",
                        "text": '{"taskId": "node:task-1", "status": "running"}',
                    }
                ],
            },
        )
        self.handle(
            "post-tool",
            {
                "session_id": "run",
                "tool_name": "mcp__t3-code__delegate_task",
                "tool_input": {"task": "Write the fix\nwith tests"},
                "tool_response": {"structuredContent": {"taskId": "node:task-2"}},
            },
        )
        self.handle(
            "post-tool",
            {
                "session_id": "run",
                "tool_name": "mcp__t3-code__delegate_task",
                "tool_input": {"task": "Quick check", "mode": "wait"},
                "tool_response": {"taskId": "node:task-3"},
            },
        )
        status: dict[str, Any] = {
            "session_id": "run",
            "tool_name": "mcp__t3-code__task_status",
            "tool_input": {"taskId": "node:task-2"},
            "tool_response": {"status": "running", "workState": "working"},
        }
        self.assertIsNone(self.handle("post-tool", status))
        status["tool_response"] = [
            {
                "type": "text",
                "text": '{"status": "completed", "workState": "result_available"}',
            }
        ]
        read = context(self.handle("post-tool", status))
        self.assertIn("Finished: Write the fix with tests (task node:task-2)", read)
        self.assertIn("Still in flight: Codex review (task node:task-1)", read)

        self.assertIsNone(self.handle("stop", stop()))
        wake = context(
            self.handle(
                "user-prompt",
                {
                    "session_id": "run",
                    "prompt": "Delegated task node:task-1 reached a terminal state. "
                    + "Use task_status with taskId node:task-1 to read the result.",
                },
            )
        )
        self.assertIn("Still in flight: none", wake)
        self.assertIsNotNone(self.handle("stop", stop()))

    def test_t3_wakes_with_inline_results_finish_lanes(self) -> None:
        for task_id in ("node:task-1", "node:task-2"):
            self.handle(
                "post-tool",
                {
                    "session_id": "run",
                    "tool_name": "mcp__t3-code__delegate_task",
                    "tool_input": {"task": "Review", "title": f"Review {task_id}"},
                    "tool_response": {"taskId": task_id},
                },
            )
        first = context(
            self.handle(
                "user-prompt",
                {
                    "session_id": "run",
                    "prompt": "Delegated task node:task-1 (Blind review (round 1)) "
                    + "[completed]: ## Verdict\nApprove (no findings).",
                },
            )
        )
        self.assertIn("Finished: Review node:task-1 (task node:task-1)", first)
        self.assertIn("Still in flight: Review node:task-2", first)
        second = context(
            self.handle(
                "user-prompt",
                {"session_id": "run", "prompt": "Delegated task node:task-2 [failed]"},
            )
        )
        self.assertIn("Still in flight: none", second)

    def test_new_request_after_lanes_drain_starts_a_new_run(self) -> None:
        self.start_two_lanes()
        self.handle("user-prompt", notification("a1"))
        self.handle("user-prompt", notification("a2"))
        self.handle(
            "user-prompt", {"session_id": "run", "prompt": "Stop hook feedback: x"}
        )
        self.assertIsNotNone(self.handle("stop", stop()))
        self.handle("user-prompt", {"session_id": "run", "prompt": "Now fix the docs"})
        self.handle("post-tool", launch("a3", "Docs pass"))
        self.assertIsNone(self.handle("user-prompt", notification("a3")))
        self.assertIsNone(self.handle("stop", stop()))

    def test_subagent_events_and_other_providers_are_ignored(self) -> None:
        child = launch("a1", "Nested")
        child["agent_id"] = "worker"
        self.handle("post-tool", child)
        self.assertIsNone(
            worker_lanes_hook.handle("copilot", "post-tool", launch("a2", "Other lane"))
        )
        self.assertFalse((self.runtime / "worker-lanes").exists())

    def test_command_line_fails_open(self) -> None:
        env = {**os.environ, "XDG_RUNTIME_DIR": str(self.runtime)}
        for args, stdin in (
            (["claude", "stop"], "not json"),
            (["claude", "post-tool"], json.dumps(launch("a1", "Lane"))),
            (["claude"], "{}"),
        ):
            with self.subTest(args=args):
                result = subprocess.run(
                    ["python3", str(HOOK), *args],
                    input=stdin,
                    text=True,
                    capture_output=True,
                    check=True,
                    env=env,
                )
                self.assertEqual(result.stdout, "")


def agy_step(kind: str, content: str = "", **extra: Any) -> dict[str, Any]:
    return {
        "step_index": 0,
        "source": "MODEL",
        "type": kind,
        "content": content,
        **extra,
    }


def agy_spawn_call(role: str) -> dict[str, Any]:
    return {
        "name": "invoke_subagent",
        "args": {"Prompt": f"Do the {role} work", "Role": role, "TypeName": "self"},
    }


class AntigravityTests(unittest.TestCase):
    runtime: Path
    transcript: Path

    def setUp(self) -> None:
        runtime = tempfile.TemporaryDirectory()
        self.addCleanup(runtime.cleanup)
        self.runtime = Path(runtime.name)
        self.transcript = self.runtime / "transcript_full.jsonl"
        self.transcript.write_text("", encoding="utf-8")
        patcher = mock.patch.dict(os.environ, {"XDG_RUNTIME_DIR": runtime.name})
        patcher.start()
        self.addCleanup(patcher.stop)

    def write(self, *steps: dict[str, Any], newline: bool = True) -> None:
        with self.transcript.open("a", encoding="utf-8") as handle:
            for step in steps:
                handle.write(json.dumps(step) + ("\n" if newline else ""))

    def handle(self, event: str, **fields: Any) -> dict[str, Any] | None:
        payload = {
            "conversationId": "parent",
            "transcriptPath": str(self.transcript),
            **fields,
        }
        return worker_lanes_hook.handle("antigravity", event, payload)

    def injected(self, output: dict[str, Any] | None) -> str:
        assert output is not None
        steps = output["injectSteps"]
        self.assertEqual(len(steps), 1)
        return steps[0]["ephemeralMessage"]

    def spawn_two(self) -> None:
        self.write(
            agy_step(
                "USER_INPUT",
                "<USER_REQUEST>port it</USER_REQUEST>",
                source="USER_EXPLICIT",
            ),
            agy_step(
                "PLANNER_RESPONSE",
                "Fanning out",
                tool_calls=[
                    agy_spawn_call("Lexer port"),
                    agy_spawn_call("Parser port"),
                ],
            ),
            agy_step(
                "INVOKE_SUBAGENT",
                'Created the following subagent: {"conversationId": "c1"}',
            ),
            agy_step(
                "GENERIC",
                "Created At: 2026-10-26T14:48:06-05:00 Created the following "
                + 'subagent: {   "conversationId": "c2",   "logAbsoluteUri": "file:///x"}',
            ),
        )
        self.assertEqual(
            self.handle("post-tool", toolCall={"name": "invoke_subagent", "args": {}}),
            {},
        )
        self.assertEqual(
            self.handle("pre-invocation", invocationNum=1), {"injectSteps": []}
        )

    def test_sessions_without_subagents_get_neutral_output_and_no_state(self) -> None:
        self.write(agy_step("USER_INPUT", "hi", source="USER_EXPLICIT"))
        self.assertEqual(
            self.handle("pre-invocation", invocationNum=0), {"injectSteps": []}
        )
        self.assertEqual(
            self.handle("stop", terminationReason="NO_TOOL_CALL", fullyIdle=True),
            {"decision": "stop"},
        )
        self.assertFalse((self.runtime / "worker-lanes").exists())

    def test_reports_trigger_refill_then_idle_stop_continues_once(self) -> None:
        self.spawn_two()
        self.write(
            agy_step(
                "SYSTEM_MESSAGE",
                "<SYSTEM_MESSAGE>\n[Message] timestamp=2026-06-26T19:43:52Z sender=c1 "
                + "priority=MESSAGE_PRIORITY_HIGH content=done",
                source="SYSTEM",
            )
        )
        reminder = self.injected(self.handle("pre-invocation", invocationNum=0))
        self.assertIn("Finished: Lexer port.", reminder)
        self.assertIn("Still in flight: Parser port.", reminder)
        self.assertEqual(
            self.handle("stop", terminationReason="NO_TOOL_CALL", fullyIdle=False),
            {"decision": "stop"},
        )
        self.write(
            agy_step(
                "SYSTEM_MESSAGE", "Subagent c2 has gone idle. Done.", source="SYSTEM"
            )
        )
        cancelled = self.handle(
            "stop", terminationReason="USER_CANCELED", fullyIdle=True
        )
        self.assertEqual(cancelled, {"decision": "stop"})
        output = self.handle("stop", terminationReason="NO_TOOL_CALL", fullyIdle=True)
        assert output is not None
        self.assertEqual(output["decision"], "continue")
        self.assertIn("No worker lane is in flight", output["reason"])
        self.assertEqual(
            self.handle("stop", terminationReason="NO_TOOL_CALL", fullyIdle=True),
            {"decision": "stop"},
        )

    def test_partial_lines_wait_and_kills_finish_lanes(self) -> None:
        self.spawn_two()
        kill = agy_step(
            "PLANNER_RESPONSE",
            "Stopping one",
            tool_calls=[
                {
                    "name": "manage_subagents",
                    "args": {"Action": "kill", "ConversationIds": ["c2"]},
                }
            ],
        )
        self.write(kill, newline=False)
        self.assertEqual(
            self.handle("pre-invocation", invocationNum=2), {"injectSteps": []}
        )
        with self.transcript.open("a", encoding="utf-8") as handle:
            handle.write("\n")
        self.assertIn(
            "Finished: Parser port.",
            self.injected(self.handle("pre-invocation", invocationNum=3)),
        )

    def test_one_read_with_launches_and_reports_keeps_their_order(self) -> None:
        self.write(
            agy_step(
                "PLANNER_RESPONSE",
                tool_calls=[agy_spawn_call("A"), agy_spawn_call("B")],
            ),
            agy_step(
                "GENERIC", 'Created the following subagent: {"conversationId": "c1"}'
            ),
            agy_step(
                "GENERIC", 'Created the following subagent: {"conversationId": "c2"}'
            ),
            agy_step(
                "SYSTEM_MESSAGE", "[Message] sender=c1 content=alpha", source="SYSTEM"
            ),
        )
        self.handle("post-tool", toolCall={"name": "invoke_subagent", "args": {}})
        reminder = self.injected(self.handle("pre-invocation", invocationNum=1))
        self.assertIn("Finished: A. Still in flight: B.", reminder)
        self.assertEqual(self.state()["peak"], 2)
        self.write(
            agy_step(
                "SYSTEM_MESSAGE", "[Message] sender=c2 content=beta", source="SYSTEM"
            ),
            agy_step("PLANNER_RESPONSE", tool_calls=[agy_spawn_call("C")]),
            agy_step(
                "GENERIC", 'Created the following subagent: {"conversationId": "c3"}'
            ),
        )
        self.assertEqual(
            self.handle("pre-invocation", invocationNum=2), {"injectSteps": []}
        )

    def state(self) -> dict[str, Any]:
        return json.loads(worker_lanes_hook.state_path("parent").read_text())

    def test_report_before_a_new_spawn_does_not_inflate_the_peak(self) -> None:
        self.write(
            agy_step("PLANNER_RESPONSE", tool_calls=[agy_spawn_call("A")]),
            agy_step(
                "GENERIC", 'Created the following subagent: {"conversationId": "c1"}'
            ),
        )
        self.handle("post-tool", toolCall={"name": "invoke_subagent", "args": {}})
        self.handle("pre-invocation", invocationNum=1)
        self.write(
            agy_step(
                "SYSTEM_MESSAGE", "[Message] sender=c1 content=done", source="SYSTEM"
            ),
            agy_step("PLANNER_RESPONSE", tool_calls=[agy_spawn_call("B")]),
            agy_step(
                "GENERIC", 'Created the following subagent: {"conversationId": "c2"}'
            ),
        )
        self.assertEqual(
            self.handle("pre-invocation", invocationNum=2), {"injectSteps": []}
        )
        self.assertEqual(self.state()["peak"], 1)
        self.assertEqual(list(self.state()["lanes"]), ["c2"])

    def test_failed_spawns_do_not_shift_later_labels(self) -> None:
        self.write(
            agy_step("PLANNER_RESPONSE", tool_calls=[agy_spawn_call("Lost")]),
            agy_step("PLANNER_RESPONSE", tool_calls=[agy_spawn_call("Lexer")]),
            agy_step(
                "GENERIC", 'Created the following subagent: {"conversationId": "c1"}'
            ),
        )
        self.handle("post-tool", toolCall={"name": "invoke_subagent", "args": {}})
        self.handle("pre-invocation", invocationNum=1)
        self.assertEqual(self.state()["lanes"]["c1"]["label"], "Lexer")

    def test_replaced_transcripts_and_bad_lines_are_read_again(self) -> None:
        self.spawn_two()
        self.transcript.unlink()
        self.transcript.write_bytes(b'{"content": "\xff"}\n')
        self.write(
            agy_step("PLANNER_RESPONSE", tool_calls=[agy_spawn_call("C")]),
            agy_step(
                "GENERIC", 'Created the following subagent: {"conversationId": "c3"}'
            ),
        )
        self.handle("pre-invocation", invocationNum=1)
        self.assertEqual(sorted(self.state()["lanes"]), ["c1", "c2", "c3"])

    def test_busy_harness_suppresses_the_backstop(self) -> None:
        self.spawn_two()
        self.write(
            agy_step("SYSTEM_MESSAGE", "Subagent c1 has gone idle.", source="SYSTEM"),
            agy_step(
                "SYSTEM_MESSAGE",
                "[Message] sender=c2 content=progress",
                source="SYSTEM",
            ),
        )
        self.assertEqual(
            self.handle("stop", terminationReason="NO_TOOL_CALL", fullyIdle=False),
            {"decision": "stop"},
        )

    def test_command_line_fails_open_with_valid_json(self) -> None:
        env = {**os.environ, "XDG_RUNTIME_DIR": str(self.runtime)}
        for event, expected in (
            ("stop", {"decision": "stop"}),
            ("pre-invocation", {"injectSteps": []}),
        ):
            with self.subTest(event=event):
                result = subprocess.run(
                    ["python3", str(HOOK), "antigravity", event],
                    input="not json",
                    text=True,
                    capture_output=True,
                    check=True,
                    env=env,
                )
                self.assertEqual(json.loads(result.stdout), expected)

    def test_drift_counts_model_steps(self) -> None:
        self.spawn_two()
        self.write(
            agy_step("SYSTEM_MESSAGE", "Subagent c1 has gone idle.", source="SYSTEM")
        )
        self.handle("pre-invocation", invocationNum=0)
        for number in range(1, worker_lanes_hook.DRIFT_STEPS):
            self.assertEqual(
                self.handle("pre-invocation", invocationNum=number), {"injectSteps": []}
            )
        drift = self.injected(self.handle("pre-invocation", invocationNum=99))
        self.assertIn("1 of 2 worker lanes are in flight", drift)


def codex_spawn(child: str, nickname: str, message: str) -> dict[str, Any]:
    return {
        "session_id": "S",
        "tool_name": "spawn_agent",
        "tool_input": {"message": message},
        "tool_response": json.dumps({"agent_id": child, "nickname": nickname}),
    }


def codex_wait(*children: str) -> dict[str, Any]:
    return {
        "session_id": "S",
        "tool_name": "multi_agent_v1wait_agent",
        "tool_input": {"targets": list(children), "timeout_ms": 120000},
        "tool_response": json.dumps(
            {
                "status": {child: {"completed": "ok"} for child in children},
                "timed_out": False,
            }
        ),
    }


class CodexTests(unittest.TestCase):
    runtime: Path

    def setUp(self) -> None:
        runtime = tempfile.TemporaryDirectory()
        self.addCleanup(runtime.cleanup)
        self.runtime = Path(runtime.name)
        patcher = mock.patch.dict(os.environ, {"XDG_RUNTIME_DIR": runtime.name})
        patcher.start()
        self.addCleanup(patcher.stop)

    def handle(self, event: str, payload: dict[str, Any]) -> dict[str, Any] | None:
        return worker_lanes_hook.handle("codex", event, {"session_id": "S", **payload})

    def spawn_two(self) -> None:
        self.assertIsNone(
            self.handle("post-tool", codex_spawn("C1", "Tesla", "Port the parser"))
        )
        self.assertIsNone(
            self.handle("post-tool", codex_spawn("C2", "Curie", "Port the lexer"))
        )

    def test_stop_with_native_workers_running_blocks_once(self) -> None:
        self.spawn_two()
        blocked = self.handle("stop", {"stop_hook_active": False})
        assert blocked is not None
        self.assertEqual(blocked["decision"], "block")
        self.assertIn(
            "will not wake you: Tesla: Port the parser (agent C1); Curie: Port the lexer (agent C2)",
            blocked["reason"],
        )
        self.assertIsNone(self.handle("stop", {"stop_hook_active": True}))

    def test_wait_results_and_child_stops_finish_lanes(self) -> None:
        self.spawn_two()
        output = self.handle("post-tool", codex_wait("C1"))
        assert output is not None
        context = output["hookSpecificOutput"]
        self.assertEqual(context["hookEventName"], "PostToolUse")
        self.assertIn(
            "Finished: Tesla: Port the parser (agent C1).", context["additionalContext"]
        )
        self.assertIn(
            "Still in flight: Curie: Port the lexer (agent C2).",
            context["additionalContext"],
        )

        self.assertIsNone(
            self.handle("subagent-stop", {"agent_id": "C2", "agent_type": "default"})
        )
        later = self.handle(
            "post-tool", {"tool_name": "exec_command", "tool_input": {}}
        )
        assert later is not None
        self.assertIn(
            "Finished: Curie: Port the lexer (agent C2).",
            later["hookSpecificOutput"]["additionalContext"],
        )

        backstop = self.handle("stop", {"stop_hook_active": False})
        assert backstop is not None
        self.assertEqual(backstop["decision"], "block")
        self.assertIn("No worker lane is in flight", backstop["reason"])

    def test_child_calls_and_notifications(self) -> None:
        self.spawn_two()
        child = {
            "tool_name": "Bash",
            "agent_id": "C1",
            "tool_input": {},
            "tool_response": "ok",
        }
        for _ in range(worker_lanes_hook.DRIFT_STEPS + 1):
            self.assertIsNone(self.handle("post-tool", child))
        notice = (
            "<subagent_notification>\n"
            + json.dumps({"agent_path": "C1", "status": {"completed": "done"}})
            + "\n</subagent_notification>"
        )
        output = self.handle("user-prompt", {"prompt": notice})
        assert output is not None
        self.assertIn(
            "Finished: Tesla: Port the parser (agent C1).",
            output["hookSpecificOutput"]["additionalContext"],
        )
        unrelated_wait = {
            "tool_name": "t3_thread_wait",
            "tool_input": {},
            "tool_response": codex_wait("C2")["tool_response"],
        }
        self.assertIsNone(self.handle("post-tool", unrelated_wait))
        self.assertEqual(list(self.lanes()), ["C2"])

    def test_close_and_terminal_statuses_finish_lanes(self) -> None:
        namespaced = codex_spawn("C1", "Ada", "one")
        namespaced["tool_name"] = "multi_agent_v1spawn_agent"
        self.handle("post-tool", namespaced)
        self.handle("post-tool", codex_spawn("C2", "Bo", "two"))
        self.handle("post-tool", codex_spawn("C3", "Cy", "three"))
        self.assertEqual(sorted(self.lanes()), ["C1", "C2", "C3"])
        self.handle(
            "post-tool", {"tool_name": "close_agent", "tool_input": {"target": "C3"}}
        )
        statuses = {"status": {"C1": {"errored": "boom"}, "C2": "not_found"}}
        self.handle(
            "post-tool",
            {
                "tool_name": "wait",
                "tool_input": {},
                "tool_response": json.dumps(statuses),
            },
        )
        self.assertEqual(self.lanes(), {})
        self.handle("post-tool", codex_spawn("C4", "Di", "four"))
        self.handle("post-tool", codex_spawn("C5", "Ed", "five"))
        mixed = {"status": {"C4": {"interrupted": ""}, "C5": {"running": ""}}}
        self.handle(
            "post-tool",
            {"tool_name": "wait_agent", "tool_input": {}, "tool_response": mixed},
        )
        self.assertEqual(list(self.lanes()), ["C5"])

    def lanes(self) -> dict[str, Any]:
        return json.loads(worker_lanes_hook.state_path("S").read_text())["lanes"]

    def test_t3_tasks_use_codex_mcp_names(self) -> None:
        self.handle(
            "post-tool",
            {
                "tool_name": "mcp__t3_code__delegate_task",
                "tool_input": {"task": "Review", "title": "Claude review"},
                "tool_response": {"taskId": "node:task-9", "status": "running"},
            },
        )
        self.spawn_two()
        # T3 tasks wake the parent, so only the native lanes hold the stop.
        output = self.handle("stop", {"stop_hook_active": False})
        assert output is not None
        self.assertIn("Tesla", output["reason"])
        self.assertNotIn("Claude review", output["reason"])
        self.assertIn("node:task-9", self.lanes())
        wake = "Delegated task node:task-9 (Claude review) [completed]: Approve."
        self.handle("user-prompt", {"prompt": wake})
        self.assertNotIn("node:task-9", self.lanes())


if __name__ == "__main__":
    unittest.main()
