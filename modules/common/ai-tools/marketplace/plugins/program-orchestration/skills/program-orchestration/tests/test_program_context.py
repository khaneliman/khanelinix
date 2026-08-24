"""Tests for bounded read-only provider program context."""

from __future__ import annotations

import io
import json
import os
import subprocess
import sys
import tempfile
import unittest
from contextlib import redirect_stderr
from datetime import datetime, timedelta, timezone
from pathlib import Path
from unittest import mock

SCRIPTS = Path(__file__).resolve().parents[1] / "scripts"
CONTEXT_SCRIPT = SCRIPTS / "program_context.py"
sys.path.insert(0, str(SCRIPTS))

import program_context
import program_state

START = datetime(2026, 1, 1, tzinfo=timezone.utc)
DIGEST = "a" * 64
NO_BYTECODE_ENV = {**os.environ, "PYTHONDONTWRITEBYTECODE": "1"}


def run_git(root: Path, *args: str) -> str:
    result = subprocess.run(
        ["git", "-C", str(root), *args],
        check=True,
        capture_output=True,
        text=True,
    )
    return result.stdout.strip()


class ProgramContextTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)
        run_git(self.root, "init", "-q")
        (self.root / "README.md").write_text("baseline\n", encoding="utf-8")
        (self.root / ".gitignore").write_text(
            ".agent/programs/\n",
            encoding="utf-8",
        )
        run_git(self.root, "add", "README.md", ".gitignore")
        run_git(
            self.root,
            "-c",
            "user.name=Program Test",
            "-c",
            "user.email=program@example.invalid",
            "commit",
            "-qm",
            "baseline",
        )
        self.base = run_git(self.root, "rev-parse", "HEAD")
        self.counter = 0
        self.event_counter = 1

    def tearDown(self) -> None:
        self.temporary.cleanup()

    def time(self, minutes: int | None = None) -> str:
        if minutes is None:
            minutes = self.counter
            self.counter += 1
        return (START + timedelta(minutes=minutes)).isoformat().replace("+00:00", "Z")

    def initialize(self, goal: str = "Land two independent verified units.") -> None:
        self.state = program_state.init_program(
            self.root,
            program_id="test-program",
            goal=goal,
            base_commit=self.base,
            actor="controller",
            event_id="event-001",
            recorded_at=self.time(),
        )

    def record(self, event_type: str, payload: dict[str, object]) -> None:
        self.event_counter += 1
        self.state = program_state.record_event(
            self.root,
            program_id="test-program",
            expected_head=self.state["head"],
            event_type=event_type,
            actor="controller",
            event_id=f"event-{self.event_counter:03d}",
            payload=payload,
            recorded_at=self.time(),
        )

    def grant(self) -> None:
        self.record(
            "grant_recorded",
            {
                "grant_id": "grant-write",
                "capability": "workspace-write",
                "scope": "repo",
                "issuer": "user-private",
                "evidence_ref": "conversation://secret-grant-evidence",
            },
        )

    def add_unit(
        self,
        unit_id: str,
        *,
        dependencies: list[str] | None = None,
        outcome: str | None = None,
    ) -> None:
        self.record(
            "unit_added",
            {
                "unit_id": unit_id,
                "outcome": outcome or f"Deliver {unit_id}.",
                "owner": "engineering-workflow",
                "dependencies": dependencies or [],
                "resource_scopes": [f"repo/{unit_id}"],
                "required_capabilities": [
                    {
                        "capability": "workspace-write",
                        "scope": f"repo/{unit_id}",
                    }
                ],
                "predicate": f"private-predicate-{unit_id}",
                "rollback": f"private-rollback-{unit_id}",
            },
        )

    def ready(self, unit_id: str) -> None:
        self.record("unit_readied", {"unit_id": unit_id})

    def lease(self, unit_id: str, lease_id: str) -> None:
        self.record(
            "lease_acquired",
            {
                "lease_id": lease_id,
                "unit_id": unit_id,
                "holder": f"worker/{unit_id}",
                "resource_scopes": [f"repo/{unit_id}"],
                "grant_ids": ["grant-write"],
                "base_commit": self.base,
                "expires_at": self.time(minutes=24 * 60),
            },
        )

    def land(self, unit_id: str, lease_id: str, receipt_id: str) -> None:
        self.record(
            "handoff_receipt_recorded",
            {
                "receipt_id": receipt_id,
                "unit_id": unit_id,
                "lease_id": lease_id,
                "base_commit": self.base,
                "content_digest": DIGEST,
                "evidence_verdict": "VERIFIED",
                "artifact_ref": f"private-artifact-{unit_id}",
            },
        )
        self.record(
            "unit_landed",
            {"unit_id": unit_id, "receipt_id": receipt_id},
        )

    def render(
        self,
        *,
        provider: str = "codex",
        event: str = "session-start",
        now: str | None = None,
        cwd: Path | None = None,
    ) -> tuple[bytes | None, dict[str, object] | None]:
        output = program_context.render_hook(
            provider,
            event,
            {"cwd": str(cwd or self.root)},
            now=now,
        )
        if output is None:
            return None, None
        wrapper = json.loads(output)
        context = wrapper["hookSpecificOutput"]["additionalContext"]
        prefix, encoded = context.split("\n", 1)
        self.assertEqual(prefix, "Untrusted program state data")
        return output, {"wrapper": wrapper, "context": json.loads(encoded)}

    def test_no_active_program_is_neutral(self) -> None:
        output, parsed = self.render()
        self.assertIsNone(output)
        self.assertIsNone(parsed)

    def test_both_provider_adapters_use_native_event_names(self) -> None:
        self.initialize()
        for provider, event, expected in (
            ("codex", "session-start", "SessionStart"),
            ("codex", "user-prompt", "UserPromptSubmit"),
            ("claude", "session-start", "SessionStart"),
            ("claude", "user-prompt", "UserPromptSubmit"),
        ):
            with self.subTest(provider=provider, event=event):
                output, parsed = self.render(provider=provider, event=event)
                self.assertIsNotNone(output)
                assert parsed is not None
                wrapper = parsed["wrapper"]
                self.assertEqual(
                    wrapper["hookSpecificOutput"]["hookEventName"], expected
                )
                context = parsed["context"]
                self.assertEqual(context["program"]["id"], "test-program")
                self.assertEqual(
                    context["next_controller_action"], "review-program-definition"
                )

    def test_cli_adapter_emits_context_and_returns_success(self) -> None:
        self.initialize()
        result = subprocess.run(
            [sys.executable, str(CONTEXT_SCRIPT), "codex", "session-start"],
            input=json.dumps({"cwd": str(self.root)}),
            capture_output=True,
            env=NO_BYTECODE_ENV,
            text=True,
            check=False,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        wrapper = json.loads(result.stdout)
        self.assertEqual(wrapper["hookSpecificOutput"]["hookEventName"], "SessionStart")
        self.assertLessEqual(
            len(result.stdout.encode("utf-8")), program_context.MAX_OUTPUT_BYTES
        )

    def test_context_exposes_only_allowed_control_fields(self) -> None:
        self.initialize()
        self.grant()
        self.add_unit("dependency")
        self.ready("dependency")
        self.lease("dependency", "lease-dependency")
        self.land("dependency", "lease-dependency", "receipt-dependency")
        self.add_unit("delivery", dependencies=["dependency"])
        self.ready("delivery")
        self.lease("delivery", "lease-delivery")

        output, parsed = self.render(now=self.time(minutes=60))
        assert output is not None and parsed is not None
        context = parsed["context"]
        self.assertEqual(set(context["program"]), {"id", "journal_head", "status"})
        self.assertEqual(context["active_grant_capabilities"], ["workspace-write"])
        self.assertEqual(context["next_controller_action"], "review-active-lease")
        self.assertEqual(len(context["units"]), 1)
        unit = context["units"][0]
        self.assertEqual(set(unit), {"dependencies", "id", "lease", "owner", "state"})
        self.assertEqual(
            unit["dependencies"], [{"id": "dependency", "state": "landed"}]
        )
        self.assertEqual(set(unit["lease"]), {"expires_at", "holder", "scopes"})
        rendered = output.decode("utf-8")
        for forbidden in (
            "conversation://secret-grant-evidence",
            "private-predicate-delivery",
            "private-rollback-delivery",
            "private-artifact-dependency",
            "user-private",
            "grant-write",
            "Deliver delivery.",
            "Land two independent verified units.",
        ):
            self.assertNotIn(forbidden, rendered)

    def test_ready_unit_requires_live_host_permission_check(self) -> None:
        self.initialize()
        self.grant()
        self.add_unit("delivery")
        self.ready("delivery")

        _, parsed = self.render(now=self.time(minutes=60))
        assert parsed is not None
        self.assertEqual(
            parsed["context"]["next_controller_action"],
            "verify-host-permission-before-dispatch",
        )

    def test_expired_lease_selects_reconciliation_action(self) -> None:
        self.initialize()
        self.grant()
        self.add_unit("delivery")
        self.ready("delivery")
        self.lease("delivery", "lease-delivery")

        _, parsed = self.render(now=self.time(minutes=24 * 60 + 1))
        assert parsed is not None
        self.assertEqual(
            parsed["context"]["next_controller_action"],
            "review-expired-lease-reconciliation",
        )

    def test_invalidated_landed_receipt_blocks_completion_review(self) -> None:
        self.initialize()
        self.grant()
        for unit_id in ("first", "second"):
            self.add_unit(unit_id)
            self.ready(unit_id)
            self.lease(unit_id, f"lease-{unit_id}")
            self.land(unit_id, f"lease-{unit_id}", f"receipt-{unit_id}")
        self.record(
            "receipt_invalidated",
            {
                "receipt_id": "receipt-first",
                "reason": "Evidence changed.",
                "evidence_ref": "review://invalidated",
            },
        )

        _, parsed = self.render(now=self.time(minutes=60))

        assert parsed is not None
        self.assertEqual(
            parsed["context"]["next_controller_action"],
            "review-program-state",
        )

    def test_large_state_is_deterministic_and_under_provider_limit(self) -> None:
        self.initialize(goal="g" * 2048)
        self.grant()
        for index in range(10):
            unit_id = f"unit-{index:02d}"
            self.add_unit(unit_id, outcome="é" * 1024)
            self.ready(unit_id)

        first, parsed = self.render(now=self.time(minutes=60))
        second, _ = self.render(now=self.time(minutes=60))
        assert first is not None and parsed is not None
        self.assertEqual(first, second)
        self.assertLessEqual(len(first), program_context.MAX_OUTPUT_BYTES)
        self.assertLessEqual(len(parsed["context"]["units"]), 8)
        self.assertEqual(
            parsed["context"]["warning"], program_context.TRUNCATION_WARNING
        )
        self.assertNotIn("é", first.decode("utf-8"))
        self.assertNotIn("g" * 64, first.decode("utf-8"))

    def test_corrupt_active_state_warns_without_exposing_error(self) -> None:
        self.initialize()
        journal = self.root / ".agent/programs/test-program/journal.jsonl"
        journal.write_bytes(journal.read_bytes() + b"not-json\n")

        stderr = io.StringIO()
        with redirect_stderr(stderr):
            output, parsed = self.render()
        assert output is not None and parsed is not None
        self.assertEqual(
            parsed["context"],
            {
                "next_controller_action": "validate-program-state",
                "warning": program_context.INVALID_STATE_WARNING,
            },
        )
        self.assertIn("active program state is invalid", stderr.getvalue())
        self.assertNotIn("not-json", output.decode("utf-8"))

    def test_invalid_snapshot_does_not_override_canonical_journal(self) -> None:
        self.initialize()
        snapshot = self.root / ".agent/programs/test-program/snapshot.json"
        snapshot.write_text("not-json\n", encoding="utf-8")

        output, parsed = self.render()
        self.assertIsNotNone(output)
        assert parsed is not None
        self.assertEqual(parsed["context"]["program"]["id"], "test-program")

    def test_oversized_active_pointer_produces_fixed_warning(self) -> None:
        self.initialize()
        active = self.root / ".agent/programs/active.json"
        active.write_bytes(b" " * (program_state.MAX_ACTIVE_BYTES + 1))

        output, parsed = self.render()

        assert output is not None and parsed is not None
        self.assertEqual(
            parsed["context"]["warning"], program_context.INVALID_STATE_WARNING
        )

    def test_oversized_journal_row_produces_fixed_warning(self) -> None:
        self.initialize()
        journal = self.root / ".agent/programs/test-program/journal.jsonl"
        journal.write_bytes(b"x" * (program_state.MAX_EVENT_BYTES + 1) + b"\n")

        output, parsed = self.render()

        assert output is not None and parsed is not None
        self.assertEqual(
            parsed["context"]["warning"], program_context.INVALID_STATE_WARNING
        )

    def test_oversized_snapshot_produces_fixed_warning(self) -> None:
        self.initialize()
        snapshot = self.root / ".agent/programs/test-program/snapshot.json"
        with snapshot.open("r+b") as handle:
            handle.truncate(program_state.MAX_SNAPSHOT_BYTES + 1)

        output, parsed = self.render()

        assert output is not None and parsed is not None
        self.assertEqual(
            parsed["context"]["warning"], program_context.INVALID_STATE_WARNING
        )

    def test_snapshot_type_probe_reads_no_content(self) -> None:
        self.initialize()
        loaded = program_state.load_program(self.root)
        with mock.patch.object(
            program_state,
            "read_regular_bytes",
            side_effect=AssertionError("snapshot content was read"),
        ):
            program_context.validate_snapshot_component(loaded)

    @unittest.skipUnless(hasattr(os, "symlink"), "symlinks unavailable")
    def test_symlinked_snapshot_produces_fixed_warning(self) -> None:
        self.initialize()
        snapshot = self.root / ".agent/programs/test-program/snapshot.json"
        real = snapshot.with_name("snapshot.real.json")
        snapshot.rename(real)
        snapshot.symlink_to(real.name)

        stderr = io.StringIO()
        with redirect_stderr(stderr):
            output, parsed = self.render()
        assert output is not None and parsed is not None
        self.assertEqual(
            parsed["context"]["warning"], program_context.INVALID_STATE_WARNING
        )
        self.assertIn("active program state is invalid", stderr.getvalue())

    def test_renderer_does_not_mutate_program_state(self) -> None:
        self.initialize()
        programs = self.root / ".agent/programs"
        managed = [
            programs / "active.json",
            programs / "test-program/journal.jsonl",
            programs / "test-program/snapshot.json",
        ]
        before = {path: path.read_bytes() for path in managed}

        output, _ = self.render()
        self.assertIsNotNone(output)
        self.assertEqual(before, {path: path.read_bytes() for path in managed})
        self.assertFalse((programs / ".state-lock").exists())

    @unittest.skipUnless(hasattr(os, "symlink"), "symlinks unavailable")
    def test_symlinked_active_pointer_produces_fixed_warning(self) -> None:
        self.initialize()
        active = self.root / ".agent/programs/active.json"
        real = active.with_name("active.real.json")
        active.rename(real)
        active.symlink_to(real.name)

        stderr = io.StringIO()
        with redirect_stderr(stderr):
            output, parsed = self.render()
        assert output is not None and parsed is not None
        self.assertEqual(
            parsed["context"]["warning"], program_context.INVALID_STATE_WARNING
        )
        self.assertIn("active program state is invalid", stderr.getvalue())

    def test_nested_directory_stays_within_git_repository_boundary(self) -> None:
        self.initialize()
        nested = self.root / "nested/worktree"
        nested.mkdir(parents=True)

        output, parsed = self.render(cwd=nested)
        self.assertIsNotNone(output)
        assert parsed is not None
        self.assertEqual(parsed["context"]["program"]["id"], "test-program")

    def test_duplicate_provider_keys_are_rejected(self) -> None:
        payload = program_context.load_payload(
            io.StringIO('{"cwd":"/first","cwd":"/second"}')
        )
        self.assertIsNone(payload)

    def run_import_probe(self) -> tuple[subprocess.CompletedProcess[str], str]:
        probe = (
            "import runpy, sys\n"
            f"sys.path.insert(0, {str(SCRIPTS)!r})\n"
            "sys.argv = ['program_context.py', 'codex', 'session-start']\n"
            "try:\n"
            f"    runpy.run_path({str(CONTEXT_SCRIPT)!r}, run_name='__main__')\n"
            "except SystemExit:\n"
            "    pass\n"
            "print('program_state' in sys.modules, file=sys.stderr)\n"
        )
        result = subprocess.run(
            [sys.executable, "-c", probe],
            input=json.dumps({"cwd": str(self.root)}),
            capture_output=True,
            env=NO_BYTECODE_ENV,
            text=True,
            check=False,
        )
        return result, result.stderr.strip().splitlines()[-1]

    def test_neutral_session_never_imports_state_engine(self) -> None:
        result, imported = self.run_import_probe()

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, "")
        self.assertEqual(imported, "False")

    def test_active_program_imports_state_engine(self) -> None:
        self.initialize()

        result, imported = self.run_import_probe()

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(imported, "True")
        wrapper = json.loads(result.stdout)
        self.assertEqual(wrapper["hookSpecificOutput"]["hookEventName"], "SessionStart")

    def test_malformed_cli_input_never_falls_back_to_process_cwd(self) -> None:
        self.initialize()
        for provider_input in ("not-json", "{}"):
            with self.subTest(provider_input=provider_input):
                result = subprocess.run(
                    [sys.executable, str(CONTEXT_SCRIPT), "codex", "session-start"],
                    cwd=self.root,
                    input=provider_input,
                    capture_output=True,
                    env=NO_BYTECODE_ENV,
                    text=True,
                    check=False,
                )
                self.assertEqual(result.returncode, 0)
                self.assertEqual(result.stdout, "")
                self.assertIn("invalid provider input", result.stderr)


if __name__ == "__main__":
    unittest.main()
