from __future__ import annotations

import importlib.util
import json
import os
import subprocess
import tempfile
import unittest
from pathlib import Path
from typing import Any
from unittest import mock

HOOK = Path(__file__).parents[1] / "worker_lanes_hook.py"
SPEC = importlib.util.spec_from_file_location("worker_lanes_hook", HOOK)
assert SPEC is not None and SPEC.loader is not None
worker_lanes_hook = importlib.util.module_from_spec(SPEC)
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

    def test_a_single_background_worker_is_not_a_fan_out_run(self) -> None:
        self.handle("post-tool", launch("a1", "Explore callers"))
        for _ in range(worker_lanes_hook.DRIFT_CALLS + 1):
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
        for _ in range(worker_lanes_hook.DRIFT_CALLS):
            self.assertIsNone(self.handle("post-tool", tool()))
        self.handle("user-prompt", notification("a1"))
        for _ in range(worker_lanes_hook.DRIFT_CALLS - 1):
            self.assertIsNone(self.handle("post-tool", tool()))
        drift = context(self.handle("post-tool", tool()))
        self.assertIn("1 of 2 worker lanes are in flight", drift)
        for _ in range(worker_lanes_hook.DRIFT_CALLS):
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
            worker_lanes_hook.handle("codex", "post-tool", launch("a2", "Codex lane"))
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


if __name__ == "__main__":
    unittest.main()
