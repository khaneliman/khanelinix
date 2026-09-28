"""Shared fixtures for the authority gate suites."""

from __future__ import annotations

import os
import sys
import tempfile
import unittest
from pathlib import Path
from typing import Any
from unittest import mock

HOOKS = Path(__file__).resolve().parents[1]
HOOK = HOOKS / "authority_gate.py"
sys.path.insert(0, str(HOOKS))

import authority_gate as hook
from authority import grants
from authority.intent import intent

# Suites import the gate through this module, which puts it on sys.path first.
__all__ = ["HOOK", "GateCase", "bash", "grants", "hook", "intent", "prompt"]


def prompt(text: str, session: str = "one", **extra: Any) -> dict[str, Any]:
    return {"session_id": session, "prompt": text, **extra}


def bash(command: str, session: str = "one", **extra: Any) -> dict[str, Any]:
    return {
        "session_id": session,
        "tool_name": "Bash",
        "tool_input": {"command": command},
        **extra,
    }


class GateCase(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name) / "state"
        self.work = Path(self.temporary.name) / "work"
        self.work.mkdir()
        # The decision log follows XDG_STATE_HOME; keep test runs out of the user's.
        environment = mock.patch.dict(
            os.environ, {"XDG_STATE_HOME": str(Path(self.temporary.name) / "xdg")}
        )
        environment.start()
        self.addCleanup(environment.stop)

    def tearDown(self) -> None:
        self.temporary.cleanup()

    def say(self, text: str, provider: str = "claude", **extra: Any) -> None:
        self.assertIsNone(
            hook.handle(provider, "user-prompt", prompt(text, **extra), self.root)
        )

    def run_tool(
        self, command: str, provider: str = "claude", **extra: Any
    ) -> dict[str, Any] | None:
        return hook.handle(
            provider, "pre-tool", bash(command, cwd=str(self.work), **extra), self.root
        )

    def assert_denied(self, command: str, fragment: str = "", **extra: Any) -> str:
        output = self.run_tool(command, **extra)
        self.assertIsNotNone(output, command)
        assert output is not None
        decision = output["hookSpecificOutput"]
        self.assertEqual(decision["permissionDecision"], "deny")
        self.assertIn(fragment, decision["permissionDecisionReason"])
        return decision["permissionDecisionReason"]

    def assert_allowed(self, command: str, **extra: Any) -> None:
        self.assertIsNone(self.run_tool(command, **extra), command)
