"""Adversarial tests for the program-control journal engine."""

from __future__ import annotations

import hashlib
import importlib.util
import json
import os
import re
import subprocess
import sys
import tempfile
import unittest
from datetime import datetime, timedelta, timezone
from pathlib import Path
from unittest import mock

SCRIPT = Path(__file__).resolve().parents[1] / "scripts" / "program_state.py"
SPEC = importlib.util.spec_from_file_location("program_state", SCRIPT)
assert SPEC is not None and SPEC.loader is not None
program_state = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = program_state
SPEC.loader.exec_module(program_state)

SCHEMA = Path(__file__).resolve().parents[1] / "schemas" / "event-v1.schema.json"
START = datetime(2026, 1, 1, tzinfo=timezone.utc)
DIGEST = "a" * 64


def run_git(root: Path, *args: str) -> str:
    result = subprocess.run(
        ["git", "-C", str(root), *args],
        check=True,
        capture_output=True,
        text=True,
    )
    return result.stdout.strip()


class ProgramStateTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)
        run_git(self.root, "init", "-q")
        (self.root / "README.md").write_text("baseline\n", encoding="utf-8")
        run_git(self.root, "add", "README.md")
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
        self.time_counter = 0
        self.event_counter = 1
        self.state = program_state.init_program(
            self.root,
            program_id="test-program",
            goal="Land two independent verified units.",
            base_commit=self.base,
            actor="controller",
            event_id="event-001",
            recorded_at=self.time(),
        )

    def tearDown(self) -> None:
        self.temporary.cleanup()

    def time(self, *, minutes: int | None = None) -> str:
        if minutes is None:
            minutes = self.time_counter
            self.time_counter += 1
        return (START + timedelta(minutes=minutes)).isoformat().replace("+00:00", "Z")

    def record(
        self,
        event_type: str,
        payload: dict[str, object],
        *,
        at: str | None = None,
        event_id: str | None = None,
    ) -> dict[str, object]:
        if event_id is None:
            self.event_counter += 1
            event_id = f"event-{self.event_counter:03d}"
        self.state = program_state.record_event(
            self.root,
            program_id="test-program",
            expected_head=self.state["head"],
            event_type=event_type,
            actor="controller",
            event_id=event_id,
            payload=payload,
            recorded_at=at or self.time(),
        )
        return self.state

    def unit(
        self,
        unit_id: str,
        *,
        dependencies: list[str] | None = None,
        scope: str | None = None,
        local_commit: bool = False,
    ) -> dict[str, object]:
        scope = scope or f"repo/{unit_id}"
        required_capabilities = [{"capability": "workspace-write", "scope": scope}]
        if local_commit:
            required_capabilities.append(
                {"capability": "local-commit", "scope": "git:local"}
            )
        required_capabilities.sort(key=lambda item: (item["capability"], item["scope"]))
        return {
            "unit_id": unit_id,
            "outcome": f"Deliver {unit_id}.",
            "owner": "engineering-workflow",
            "dependencies": dependencies or [],
            "resource_scopes": [scope],
            "required_capabilities": required_capabilities,
            "predicate": f"{unit_id} predicate passes.",
            "rollback": f"Revert {unit_id}.",
        }

    def grant(
        self,
        grant_id: str = "grant-write",
        *,
        capability: str = "workspace-write",
        scope: str | None = None,
        expires_at: str | None = None,
    ) -> dict[str, object]:
        scope = scope or ("git:local" if capability == "local-commit" else "repo")
        payload: dict[str, object] = {
            "grant_id": grant_id,
            "capability": capability,
            "scope": scope,
            "issuer": "user",
            "evidence_ref": "conversation://grant",
        }
        if expires_at is not None:
            payload["expires_at"] = expires_at
        return payload

    def lease(
        self,
        unit_id: str,
        lease_id: str,
        *,
        grant_ids: list[str] | None = None,
        scope: str | None = None,
        expires_at: str | None = None,
    ) -> dict[str, object]:
        return {
            "lease_id": lease_id,
            "unit_id": unit_id,
            "holder": f"worker/{unit_id}",
            "resource_scopes": [scope or f"repo/{unit_id}"],
            "grant_ids": grant_ids or ["grant-write"],
            "base_commit": run_git(self.root, "rev-parse", "HEAD"),
            "expires_at": expires_at or self.time(minutes=120),
        }

    def handoff_receipt(
        self, unit_id: str, lease_id: str, receipt_id: str, *, verdict: str
    ) -> dict[str, object]:
        return {
            "receipt_id": receipt_id,
            "unit_id": unit_id,
            "lease_id": lease_id,
            "base_commit": self.state["leases"][lease_id]["base_commit"],
            "content_digest": DIGEST,
            "evidence_verdict": verdict,
            "artifact_ref": f"patch://{unit_id}",
        }

    def land_handoff(self, unit_id: str, lease_id: str, receipt_id: str) -> None:
        self.record(
            "handoff_receipt_recorded",
            self.handoff_receipt(unit_id, lease_id, receipt_id, verdict="VERIFIED"),
        )
        self.record(
            "unit_landed",
            {"unit_id": unit_id, "receipt_id": receipt_id},
        )

    def prepare_unit(
        self,
        unit_id: str,
        lease_id: str,
        *,
        dependencies: list[str] | None = None,
        scope: str | None = None,
        local_commit: bool = False,
        grant_ids: list[str] | None = None,
    ) -> None:
        self.record(
            "unit_added",
            self.unit(
                unit_id,
                dependencies=dependencies,
                scope=scope,
                local_commit=local_commit,
            ),
        )
        self.record("unit_readied", {"unit_id": unit_id})
        self.record(
            "lease_acquired",
            self.lease(
                unit_id,
                lease_id,
                scope=scope,
                grant_ids=grant_ids,
            ),
        )

    def test_init_writes_canonical_valid_state(self) -> None:
        loaded = program_state.load_program(self.root)

        self.assertEqual(loaded.state["status"], "active")
        self.assertEqual(loaded.state["sequence"], 1)
        self.assertEqual(
            program_state.read_snapshot_status(loaded.snapshot_path, loaded.state),
            "current",
        )
        journal = loaded.journal_path.read_bytes()
        self.assertTrue(journal.endswith(b"\n"))
        self.assertEqual(journal, program_state.journal_bytes(loaded.events))

    def test_complete_two_unit_program(self) -> None:
        self.record("grant_recorded", self.grant())
        self.prepare_unit("unit-a", "lease-a")
        self.land_handoff("unit-a", "lease-a", "receipt-a")
        self.prepare_unit("unit-b", "lease-b", dependencies=["unit-a"])
        self.land_handoff("unit-b", "lease-b", "receipt-b")

        self.record(
            "program_completed",
            {"evidence_ref": "check://all-units"},
        )

        self.assertEqual(self.state["status"], "completed")
        self.assertEqual(self.state["units"]["unit-b"]["status"], "landed")

    def test_expected_head_rejects_without_changing_journal(self) -> None:
        before = program_state.load_program(self.root).journal_path.read_bytes()

        with self.assertRaisesRegex(program_state.ProgramError, "expected head"):
            program_state.record_event(
                self.root,
                program_id="test-program",
                expected_head="f" * 64,
                event_type="grant_recorded",
                actor="controller",
                event_id="event-cas",
                payload=self.grant(),
                recorded_at=self.time(),
            )

        self.assertEqual(
            program_state.load_program(self.root).journal_path.read_bytes(),
            before,
        )

    def test_hash_tampering_and_noncanonical_lines_fail_replay(self) -> None:
        loaded = program_state.load_program(self.root)
        event = dict(loaded.events[0])
        event["payload"] = dict(event["payload"])
        event["payload"]["goal"] = "Tampered."
        loaded.journal_path.write_bytes(program_state.canonical_json(event) + b"\n")

        with self.assertRaisesRegex(program_state.ProgramError, "hash mismatch"):
            program_state.load_program(self.root)

    def test_boolean_schema_version_is_rejected(self) -> None:
        loaded = program_state.load_program(self.root)
        event = dict(loaded.events[0])
        event["schema_version"] = True
        event["event_hash"] = program_state.event_digest(event)

        with self.assertRaisesRegex(
            program_state.ProgramError, "unsupported schema version"
        ):
            program_state.validate_event_shape(event)

        loaded.journal_path.write_bytes(
            json.dumps(loaded.events[0], indent=2).encode("utf-8") + b"\n"
        )
        with self.assertRaisesRegex(
            program_state.ProgramError, "invalid JSON|canonical"
        ):
            program_state.load_program(self.root)

    def test_unknown_payload_and_duplicate_event_id_fail(self) -> None:
        payload = self.grant()
        payload["invented"] = True
        with self.assertRaisesRegex(program_state.ProgramError, "unknown fields"):
            self.record("grant_recorded", payload)

        self.record(
            "grant_recorded",
            self.grant(),
            event_id="event-stable",
        )
        with self.assertRaisesRegex(program_state.ProgramError, "already recorded"):
            self.record(
                "unit_added",
                self.unit("unit-a"),
                event_id="event-stable",
            )

    def test_expired_lease_keeps_conflicting_scope_until_reconciled(self) -> None:
        self.record("grant_recorded", self.grant())
        self.record("unit_added", self.unit("unit-a", scope="repo/shared"))
        self.record("unit_readied", {"unit_id": "unit-a"})
        self.record(
            "unit_added",
            self.unit("unit-b", scope="repo/shared/child"),
        )
        self.record("unit_readied", {"unit_id": "unit-b"})
        self.record(
            "lease_acquired",
            self.lease(
                "unit-a",
                "lease-a",
                scope="repo/shared",
                expires_at=self.time(minutes=10),
            ),
        )

        with self.assertRaisesRegex(program_state.ProgramError, "overlap"):
            self.record(
                "lease_acquired",
                self.lease(
                    "unit-b",
                    "lease-b",
                    scope="repo/shared/child",
                    expires_at=self.time(minutes=20),
                ),
                at=self.time(minutes=11),
            )

        self.record(
            "lease_reconciled",
            {
                "lease_id": "lease-a",
                "outcome": "released",
                "reason": "Workspace inspected.",
                "evidence_ref": "workspace://inspection",
            },
            at=self.time(minutes=12),
        )
        self.record(
            "lease_acquired",
            self.lease(
                "unit-b",
                "lease-b",
                scope="repo/shared/child",
                expires_at=self.time(minutes=30),
            ),
            at=self.time(minutes=13),
        )
        self.assertEqual(self.state["units"]["unit-b"]["status"], "leased")

    def test_expired_or_revoked_grant_prevents_dispatch(self) -> None:
        self.record(
            "grant_recorded",
            self.grant(expires_at=self.time(minutes=5)),
        )
        self.record("unit_added", self.unit("unit-a"))

        with self.assertRaisesRegex(program_state.ProgramError, "lack active"):
            self.record(
                "unit_readied",
                {"unit_id": "unit-a"},
                at=self.time(minutes=6),
            )

    def test_unverified_receipt_cannot_land(self) -> None:
        self.record("grant_recorded", self.grant())
        self.prepare_unit("unit-a", "lease-a")
        self.record(
            "handoff_receipt_recorded",
            self.handoff_receipt(
                "unit-a", "lease-a", "receipt-bad", verdict="INCONCLUSIVE"
            ),
        )

        with self.assertRaisesRegex(program_state.ProgramError, "VERIFIED"):
            self.record(
                "unit_landed",
                {"unit_id": "unit-a", "receipt_id": "receipt-bad"},
            )

    def test_grant_revocation_after_receipt_prevents_landing(self) -> None:
        self.record("grant_recorded", self.grant())
        self.prepare_unit("unit-a", "lease-a")
        self.record(
            "handoff_receipt_recorded",
            self.handoff_receipt("unit-a", "lease-a", "receipt-a", verdict="VERIFIED"),
        )
        self.record(
            "grant_revoked",
            {"grant_id": "grant-write", "reason": "User revoked write access."},
        )

        with self.assertRaisesRegex(program_state.ProgramError, "inactive grant"):
            self.record(
                "unit_landed",
                {"unit_id": "unit-a", "receipt_id": "receipt-a"},
            )

    def test_lease_expiry_after_receipt_prevents_landing(self) -> None:
        self.record("grant_recorded", self.grant())
        self.prepare_unit("unit-a", "lease-a")
        self.record(
            "handoff_receipt_recorded",
            self.handoff_receipt("unit-a", "lease-a", "receipt-a", verdict="VERIFIED"),
        )

        with self.assertRaisesRegex(program_state.ProgramError, "current lease"):
            self.record(
                "unit_landed",
                {"unit_id": "unit-a", "receipt_id": "receipt-a"},
                at=self.time(minutes=121),
            )

    def test_revoked_lease_grant_prevents_receipt_delivery(self) -> None:
        self.record("grant_recorded", self.grant())
        self.prepare_unit("unit-a", "lease-a")
        self.record(
            "grant_revoked",
            {"grant_id": "grant-write", "reason": "User revoked write access."},
        )

        with self.assertRaisesRegex(program_state.ProgramError, "inactive grant"):
            self.record(
                "handoff_receipt_recorded",
                self.handoff_receipt(
                    "unit-a", "lease-a", "receipt-a", verdict="VERIFIED"
                ),
            )

    def test_occurrence_requires_real_parent_and_digest_equality(self) -> None:
        self.record("grant_recorded", self.grant())
        self.record(
            "grant_recorded",
            self.grant(
                "grant-commit",
                capability="local-commit",
            ),
        )
        self.prepare_unit(
            "unit-a",
            "lease-a",
            local_commit=True,
            grant_ids=["grant-commit", "grant-write"],
        )
        (self.root / "README.md").write_text("candidate\n", encoding="utf-8")
        run_git(self.root, "add", "README.md")
        run_git(
            self.root,
            "-c",
            "user.name=Program Test",
            "-c",
            "user.email=program@example.invalid",
            "commit",
            "-qm",
            "candidate",
        )
        commit = run_git(self.root, "rev-parse", "HEAD")
        self.record(
            "occurrence_receipt_recorded",
            {
                "receipt_id": "receipt-occurrence",
                "unit_id": "unit-a",
                "lease_id": "lease-a",
                "base_commit": self.base,
                "content_digest": "b" * 64,
                "evidence_verdict": "VERIFIED",
                "artifact_ref": "receipt://unit-a",
                "commit_sha": commit,
                "parent_sha": self.base,
                "committed_digest": "c" * 64,
                "digest_match": False,
            },
        )

        with self.assertRaisesRegex(program_state.ProgramError, "digest equality"):
            self.record(
                "unit_landed",
                {
                    "unit_id": "unit-a",
                    "receipt_id": "receipt-occurrence",
                },
            )

    def test_occurrence_commit_must_be_repository_head(self) -> None:
        self.record("grant_recorded", self.grant())
        self.record(
            "grant_recorded",
            self.grant("grant-commit", capability="local-commit"),
        )
        self.prepare_unit(
            "unit-a",
            "lease-a",
            local_commit=True,
            grant_ids=["grant-commit", "grant-write"],
        )
        (self.root / "README.md").write_text("side commit\n", encoding="utf-8")
        run_git(self.root, "add", "README.md")
        run_git(
            self.root,
            "-c",
            "user.name=Program Test",
            "-c",
            "user.email=program@example.invalid",
            "commit",
            "-qm",
            "side commit",
        )
        side_commit = run_git(self.root, "rev-parse", "HEAD")
        run_git(self.root, "checkout", "-q", "--detach", self.base)

        with self.assertRaisesRegex(program_state.ProgramError, "repository HEAD"):
            self.record(
                "occurrence_receipt_recorded",
                {
                    "receipt_id": "receipt-side",
                    "unit_id": "unit-a",
                    "lease_id": "lease-a",
                    "base_commit": self.base,
                    "content_digest": DIGEST,
                    "evidence_verdict": "VERIFIED",
                    "artifact_ref": "receipt://side",
                    "commit_sha": side_commit,
                    "parent_sha": self.base,
                    "committed_digest": DIGEST,
                    "digest_match": True,
                },
            )

    def test_occurrence_commit_must_remain_head_until_landing(self) -> None:
        self.record("grant_recorded", self.grant())
        self.record(
            "grant_recorded",
            self.grant("grant-commit", capability="local-commit"),
        )
        self.prepare_unit(
            "unit-a",
            "lease-a",
            local_commit=True,
            grant_ids=["grant-commit", "grant-write"],
        )
        (self.root / "README.md").write_text("candidate\n", encoding="utf-8")
        run_git(self.root, "add", "README.md")
        run_git(
            self.root,
            "-c",
            "user.name=Program Test",
            "-c",
            "user.email=program@example.invalid",
            "commit",
            "-qm",
            "candidate",
        )
        commit = run_git(self.root, "rev-parse", "HEAD")
        self.record(
            "occurrence_receipt_recorded",
            {
                "receipt_id": "receipt-a",
                "unit_id": "unit-a",
                "lease_id": "lease-a",
                "base_commit": self.base,
                "content_digest": DIGEST,
                "evidence_verdict": "VERIFIED",
                "artifact_ref": "receipt://unit-a",
                "commit_sha": commit,
                "parent_sha": self.base,
                "committed_digest": DIGEST,
                "digest_match": True,
            },
        )
        (self.root / "later.txt").write_text("later\n", encoding="utf-8")
        run_git(self.root, "add", "later.txt")
        run_git(
            self.root,
            "-c",
            "user.name=Program Test",
            "-c",
            "user.email=program@example.invalid",
            "commit",
            "-qm",
            "later",
        )

        with self.assertRaisesRegex(program_state.ProgramError, "remain.*HEAD"):
            self.record(
                "unit_landed",
                {"unit_id": "unit-a", "receipt_id": "receipt-a"},
            )

    def test_invalidated_dependency_blocks_receipt_delivery(self) -> None:
        self.record("grant_recorded", self.grant())
        self.prepare_unit("unit-a", "lease-a")
        self.land_handoff("unit-a", "lease-a", "receipt-a")
        self.prepare_unit("unit-b", "lease-b", dependencies=["unit-a"])
        self.record(
            "receipt_invalidated",
            {
                "receipt_id": "receipt-a",
                "reason": "Dependency evidence changed.",
                "evidence_ref": "git://rewrite",
            },
        )

        with self.assertRaisesRegex(
            program_state.ProgramError, "invalidated dependency"
        ):
            self.record(
                "handoff_receipt_recorded",
                self.handoff_receipt(
                    "unit-b", "lease-b", "receipt-b", verdict="VERIFIED"
                ),
            )

    def test_dependency_reopens_in_reverse_order_only(self) -> None:
        self.record("grant_recorded", self.grant())
        self.prepare_unit("unit-a", "lease-a")
        self.land_handoff("unit-a", "lease-a", "receipt-a")
        self.prepare_unit("unit-b", "lease-b", dependencies=["unit-a"])
        self.land_handoff("unit-b", "lease-b", "receipt-b")
        self.record(
            "receipt_invalidated",
            {
                "receipt_id": "receipt-a",
                "reason": "Base changed.",
                "evidence_ref": "git://rewrite",
            },
        )

        with self.assertRaisesRegex(program_state.ProgramError, "dependent"):
            self.record(
                "unit_reopened",
                {
                    "unit_id": "unit-a",
                    "receipt_id": "receipt-a",
                    "reason": "Re-run unit.",
                    "evidence_ref": "git://rewrite",
                },
            )

    def test_snapshot_failure_leaves_recoverable_journal(self) -> None:
        original = program_state.atomic_write

        def fail_snapshot(path: Path, data: bytes) -> None:
            if path.name == "snapshot.json":
                raise program_state.ProgramError("injected snapshot failure")
            original(path, data)

        with (
            mock.patch.object(program_state, "atomic_write", fail_snapshot),
            self.assertRaisesRegex(
                program_state.ProgramError, "injected snapshot failure"
            ),
        ):
            self.record(
                "grant_recorded",
                self.grant(),
                event_id="event-uncertain",
            )

        loaded = program_state.load_program(self.root)
        with self.assertRaisesRegex(program_state.ProgramError, "already recorded"):
            program_state.record_event(
                self.root,
                program_id="test-program",
                expected_head=self.state["head"],
                event_type="grant_recorded",
                actor="controller",
                event_id="event-uncertain",
                payload=self.grant(),
                recorded_at=self.time(),
            )
        lookup = subprocess.run(
            [
                sys.executable,
                "-B",
                str(SCRIPT),
                "validate",
                str(self.root),
                "--event-id",
                "event-uncertain",
            ],
            check=False,
            capture_output=True,
            text=True,
        )
        self.assertEqual(lookup.returncode, 0)
        self.assertTrue(json.loads(lookup.stdout)["event_lookup"]["found"])
        self.state = loaded.state
        self.assertIn("grant-write", loaded.state["grants"])
        self.assertEqual(
            program_state.read_snapshot_status(loaded.snapshot_path, loaded.state),
            "stale",
        )
        program_state.recovery_apply(
            self.root,
            program_id="test-program",
            expected_head=loaded.state["head"],
            action="rebuild-snapshot",
        )
        loaded = program_state.load_program(self.root)
        self.assertEqual(
            program_state.read_snapshot_status(loaded.snapshot_path, loaded.state),
            "current",
        )

    def test_stale_lock_requires_exact_token_and_evidence(self) -> None:
        programs = self.root / ".agent" / "programs"
        lock = programs / ".state-lock"
        lock.mkdir()
        owner = {
            "token": "abc123",
            "pid": 999999,
            "host": "test-host",
            "created_at": self.time(minutes=1),
        }
        (lock / "owner.json").write_bytes(program_state.canonical_json(owner) + b"\n")

        with self.assertRaisesRegex(program_state.ProgramError, "lock exists"):
            self.record("grant_recorded", self.grant())
        plan = program_state.recovery_plan(
            self.root,
            program_id="test-program",
            observed_at=self.time(minutes=10),
        )
        self.assertEqual(plan["lock"]["token"], "abc123")
        with self.assertRaisesRegex(program_state.ProgramError, "token changed"):
            program_state.recovery_apply(
                self.root,
                program_id="test-program",
                expected_head=self.state["head"],
                action="remove-lock",
                lock_token="wrong",
                evidence_ref="process://checked",
            )
        result = program_state.recovery_apply(
            self.root,
            program_id="test-program",
            expected_head=self.state["head"],
            action="remove-lock",
            lock_token="abc123",
            evidence_ref="process://checked",
        )
        self.assertEqual(result["action"], "remove-lock")
        self.assertFalse(lock.exists())

    def test_recovery_removes_only_exact_temporary(self) -> None:
        program_dir = self.root / ".agent" / "programs" / "test-program"
        temporary = program_dir / ".journal.jsonl.tmp.deadbeef"
        temporary.write_bytes(b"orphan")
        digest = hashlib.sha256(b"orphan").hexdigest()
        with self.assertRaisesRegex(program_state.ProgramError, "digest changed"):
            program_state.recovery_apply(
                self.root,
                program_id="test-program",
                expected_head=self.state["head"],
                action="remove-temp",
                relative_path="test-program/.journal.jsonl.tmp.deadbeef",
                expected_file_digest="f" * 64,
            )
        program_state.recovery_apply(
            self.root,
            program_id="test-program",
            expected_head=self.state["head"],
            action="remove-temp",
            relative_path="test-program/.journal.jsonl.tmp.deadbeef",
            expected_file_digest=digest,
        )
        self.assertFalse(temporary.exists())

    def test_recovery_replaces_invalid_regular_active_pointer(self) -> None:
        active = self.root / ".agent" / "programs" / "active.json"
        active.write_text("{invalid\n", encoding="utf-8")

        program_state.recovery_apply(
            self.root,
            program_id="test-program",
            expected_head=self.state["head"],
            action="restore-active",
        )

        self.assertEqual(
            json.loads(active.read_text(encoding="utf-8"))["program_id"],
            "test-program",
        )

    @unittest.skipUnless(hasattr(os, "symlink"), "symlinks unavailable")
    def test_symlinked_active_pointer_is_rejected(self) -> None:
        active = self.root / ".agent" / "programs" / "active.json"
        target = self.root / "outside.json"
        target.write_text(
            '{"schema_version":1,"program_id":"test-program"}\n',
            encoding="utf-8",
        )
        active.unlink()
        active.symlink_to(target)

        with self.assertRaisesRegex(program_state.ProgramError, "non-symlink"):
            program_state.load_program(self.root)

    def test_schema_registry_matches_engine_payload_keys(self) -> None:
        schema = json.loads(SCHEMA.read_text(encoding="utf-8"))
        refs = {
            item["if"]["properties"]["event_type"]["const"]: item["then"]["properties"][
                "payload"
            ]["$ref"].rsplit("/", 1)[1]
            for item in schema["allOf"]
        }
        self.assertEqual(set(refs), set(program_state.PAYLOAD_SPECS))
        for event_type, definition_name in refs.items():
            definition = schema["$defs"][definition_name]
            required, optional = program_state.PAYLOAD_SPECS[event_type]
            self.assertEqual(set(definition["required"]), set(required))
            self.assertEqual(
                set(definition["properties"]),
                set(required) | set(optional),
            )
        self.assertEqual(
            set(schema["$defs"]["capability"]["enum"]),
            program_state.CAPABILITIES,
        )
        self.assertEqual(
            set(schema["$defs"]["verdict"]["enum"]),
            program_state.VERDICTS,
        )
        self.assertEqual(
            set(schema["$defs"]["leaseReconciled"]["properties"]["outcome"]["enum"]),
            program_state.LEASE_OUTCOMES,
        )

    def test_schema_primitive_patterns_match_engine_rules(self) -> None:
        schema = json.loads(SCHEMA.read_text(encoding="utf-8"))
        cases = {
            "text": (
                ("Valid text.",),
                (" leading", "trailing ", "two\nlines"),
                "text",
            ),
            "reference": (
                ("artifact://receipt",),
                (" artifact://receipt", "artifact://receipt "),
                "reference",
            ),
            "scope": (
                ("repo/path", "git:local"),
                ("/repo", "repo/", "repo//path", "repo/../path", r"repo\path"),
                "scope",
            ),
        }
        for definition, (accepted, rejected, kind) in cases.items():
            pattern = re.compile(schema["$defs"][definition]["pattern"])
            for value in accepted:
                with self.subTest(definition=definition, value=value):
                    self.assertIsNotNone(pattern.fullmatch(value))
                    program_state.validate_field(kind, value, definition)
            for value in rejected:
                with self.subTest(definition=definition, value=value):
                    self.assertIsNone(pattern.fullmatch(value))
                    with self.assertRaises(program_state.ProgramError):
                        program_state.validate_field(kind, value, definition)

    def test_sorted_arrays_have_closed_size_and_order(self) -> None:
        payload = self.unit("unit-a")
        payload["dependencies"] = ["zeta", "alpha"]
        with self.assertRaisesRegex(program_state.ProgramError, "lexically sorted"):
            program_state.validate_payload("unit_added", payload)

        payload = self.unit("unit-a")
        payload["dependencies"] = [
            f"unit-{index:03d}" for index in range(program_state.MAX_ARRAY_ITEMS + 1)
        ]
        with self.assertRaises(program_state.ProgramError):
            program_state.validate_payload("unit_added", payload)

    def test_cli_reports_structured_status_and_error(self) -> None:
        status = subprocess.run(
            [sys.executable, "-B", str(SCRIPT), "status", str(self.root)],
            check=False,
            capture_output=True,
            text=True,
        )
        self.assertEqual(status.returncode, 0)
        self.assertTrue(json.loads(status.stdout)["ok"])

        invalid = subprocess.run(
            [
                sys.executable,
                "-B",
                str(SCRIPT),
                "record",
                str(self.root),
                "--program-id",
                "test-program",
                "--expected-head",
                "bad",
                "--event-type",
                "unit_readied",
                "--actor",
                "controller",
                "--event-id",
                "cli-event",
                "--payload-file",
                "-",
            ],
            input='{"unit_id":"unit-a"}',
            check=False,
            capture_output=True,
            text=True,
        )
        self.assertEqual(invalid.returncode, 2)
        self.assertFalse(json.loads(invalid.stderr)["ok"])

        argument_error = subprocess.run(
            [
                sys.executable,
                "-B",
                str(SCRIPT),
                "record",
                str(self.root),
                "--program-id",
                "test-program",
                "--expected-head",
                self.state["head"],
                "--event-type",
                "invented",
                "--actor",
                "controller",
                "--event-id",
                "cli-event",
                "--payload-file",
                "-",
            ],
            input="{}",
            check=False,
            capture_output=True,
            text=True,
        )
        self.assertEqual(argument_error.returncode, 2)
        self.assertFalse(json.loads(argument_error.stderr)["ok"])
        self.assertNotIn("usage:", argument_error.stderr)


if __name__ == "__main__":
    unittest.main()
