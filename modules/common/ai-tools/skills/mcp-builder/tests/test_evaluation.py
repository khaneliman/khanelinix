from __future__ import annotations

import copy
import importlib.util
import sys
import unittest
from pathlib import Path
from types import ModuleType, SimpleNamespace
from unittest.mock import AsyncMock, Mock, patch

# Mock optional network dependencies so the real loop can run entirely offline.
spec = importlib.util.spec_from_file_location(
    "evaluation", Path(__file__).parents[1] / "scripts" / "evaluation.py"
)
evaluation = importlib.util.module_from_spec(spec)
anthropic = ModuleType("anthropic")
anthropic.Anthropic = Mock()
connections = ModuleType("connections")
connections.create_connection = Mock()
with patch.dict(sys.modules, {"anthropic": anthropic, "connections": connections}):
    spec.loader.exec_module(evaluation)


def tool(identifier, name, arguments):
    return SimpleNamespace(type="tool_use", id=identifier, name=name, input=arguments)


class AgentLoopTest(unittest.IsolatedAsyncioTestCase):
    async def run_loop(self, turns, outcomes):
        requests = []
        responses = iter(turns)

        def create(**kwargs):
            requests.append(copy.deepcopy(kwargs))
            return next(responses)

        client = SimpleNamespace(messages=SimpleNamespace(create=create))
        connection = SimpleNamespace(call_tool=AsyncMock(side_effect=outcomes))
        result = await evaluation.agent_loop(
            client, "mock-model", "question", [], connection
        )
        return result, requests, connection

    async def test_all_tools_are_mapped_before_next_request(self):
        turns = [
            SimpleNamespace(
                stop_reason="tool_use",
                content=[
                    SimpleNamespace(type="text", text="Working"),
                    tool("a", "lookup", {"id": 1}),
                    tool("b", "lookup", {"id": 2}),
                    tool("c", "other", {}),
                ],
            ),
            SimpleNamespace(
                stop_reason="tool_use", content=[tool("d", "other", {"id": 3})]
            ),
            SimpleNamespace(
                stop_reason="end_turn",
                content=[SimpleNamespace(type="text", text="done")],
            ),
        ]
        (text, metrics), requests, connection = await self.run_loop(
            turns, [{"one": 1}, ["two"], "three", "four"]
        )
        self.assertEqual(text, "done")
        self.assertEqual(
            connection.call_tool.await_args_list,
            [
                unittest.mock.call("lookup", {"id": 1}),
                unittest.mock.call("lookup", {"id": 2}),
                unittest.mock.call("other", {}),
                unittest.mock.call("other", {"id": 3}),
            ],
        )
        results = requests[1]["messages"][-1]
        self.assertEqual(results["role"], "user")
        self.assertEqual(
            [r["tool_use_id"] for r in results["content"]], ["a", "b", "c"]
        )
        self.assertEqual(
            [r["content"] for r in results["content"]],
            ['{"one": 1}', '["two"]', "three"],
        )
        self.assertTrue(all(not r.get("is_error", False) for r in results["content"]))
        self.assertEqual(requests[2]["messages"][-1]["content"][0]["tool_use_id"], "d")
        self.assertEqual(metrics["lookup"]["count"], 2)
        self.assertEqual(metrics["other"]["count"], 2)
        self.assertTrue(
            all(len(m["durations"]) == m["count"] for m in metrics.values())
        )

    async def test_error_does_not_drop_remaining_tools(self):
        turns = [
            SimpleNamespace(
                stop_reason="tool_use",
                content=[
                    tool("failed", "broken", {}),
                    tool("ok", "working", {}),
                ],
            ),
            SimpleNamespace(
                stop_reason="end_turn",
                content=[SimpleNamespace(type="text", text="done")],
            ),
        ]
        (_, metrics), requests, connection = await self.run_loop(
            turns, [ValueError("bad input"), "ok"]
        )
        results = requests[1]["messages"][-1]["content"]
        self.assertEqual([r["tool_use_id"] for r in results], ["failed", "ok"])
        self.assertTrue(results[0]["is_error"])
        self.assertIn("bad input", results[0]["content"])
        self.assertEqual(results[1]["content"], "ok")
        self.assertFalse(results[1].get("is_error", False))
        self.assertEqual(connection.call_tool.await_count, 2)
        self.assertEqual(metrics["broken"]["count"], 1)
        self.assertEqual(metrics["working"]["count"], 1)

    async def test_no_tools_preserves_final_text(self):
        turns = [
            SimpleNamespace(
                stop_reason="end_turn",
                content=[SimpleNamespace(type="text", text="done")],
            )
        ]
        (text, metrics), requests, connection = await self.run_loop(turns, [])
        self.assertEqual((text, metrics), ("done", {}))
        self.assertEqual(len(requests), 1)
        connection.call_tool.assert_not_awaited()


if __name__ == "__main__":
    unittest.main()
