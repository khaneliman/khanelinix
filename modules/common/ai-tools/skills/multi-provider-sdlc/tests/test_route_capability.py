from __future__ import annotations

import errno
import importlib.util
import json
import os
import shutil
import stat
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock

SKILL_ROOT = Path(__file__).resolve().parents[1]
SCRIPT = SKILL_ROOT / "scripts" / "route-capability.py"
GOOGLE_QUOTA = SKILL_ROOT / "scripts" / "check-google-quota.sh"
SPEC = importlib.util.spec_from_file_location("route_capability", SCRIPT)
assert SPEC is not None and SPEC.loader is not None
capability = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = capability
SPEC.loader.exec_module(capability)


class RouteCapabilityTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)
        self.state = self.root / "capability.json"
        self.task_id = "task-001"
        self.registry = capability.load_registry()

    def tearDown(self) -> None:
        self.temporary.cleanup()

    def initialize(self) -> dict[str, object]:
        return capability.initialize(self.state, self.task_id)

    def load_state(self) -> dict[str, object]:
        return json.loads(self.state.read_text(encoding="utf-8"))

    def need_for_model(self, model: str) -> str:
        for route in self.registry["task_routes"]:
            if model in route["preferred"]:
                return route["need"]
        for route in self.registry["task_routes"]:
            if model in route["fallbacks"]:
                return route["need"]
        self.fail(f"test model has no task route: {model}")

    def claim(
        self,
        model: str,
        expected_revision: int = 0,
        need: str | None = None,
        override_reason: str | None = None,
    ) -> dict[str, object]:
        return capability.claim_route(
            self.state,
            self.task_id,
            expected_revision,
            need or self.need_for_model(model),
            model,
            override_reason,
        )

    def complete(
        self,
        model: str,
        outcome: str,
        expected_revision: int = 0,
    ) -> dict[str, object]:
        claim = self.claim(model, expected_revision)
        return capability.record_outcome(
            self.state,
            self.task_id,
            claim["claimId"],
            outcome,
        )

    def run_cli(self, *arguments: str) -> dict[str, object]:
        environment = os.environ.copy()
        environment["PYTHONDONTWRITEBYTECODE"] = "1"
        result = subprocess.run(
            [
                sys.executable,
                "-B",
                str(SCRIPT),
                "--state",
                str(self.state),
                "--task-id",
                self.task_id,
                *arguments,
            ],
            check=True,
            capture_output=True,
            text=True,
            env=environment,
        )
        return json.loads(result.stdout)

    def pool_models(self, pool: str) -> list[str]:
        return sorted(
            model_id
            for model_id, model in self.registry["models"].items()
            if model["subscription"] == "google" and model["quota_pool"] == pool
        )

    def google_telemetry(
        self,
        claude_status: str = "available",
        gemini_status: str = "available",
    ) -> dict[str, object]:
        def report(pool: str, status_value: str) -> dict[str, object]:
            value: dict[str, object] = {
                "status": status_value,
                "models": self.pool_models(pool),
            }
            if status_value == "unknown":
                value["reason"] = "quota-data-missing"
            return value

        return {
            "provider": "google",
            "pools": {
                "claude-gpt": report("claude-gpt", claude_status),
                "gemini": report("gemini", gemini_status),
            },
        }

    def test_skill_routes_reusable_circuits_to_capability_script(self) -> None:
        skill = (SKILL_ROOT / "SKILL.md").read_text(encoding="utf-8")
        routing = (SKILL_ROOT / "references" / "routing.md").read_text(encoding="utf-8")

        self.assertIn("task-local capability state", skill)
        self.assertIn("route-capability.py", routing)
        self.assertIn("Skip the\nstate file for one known dispatch", routing)
        self.assertIn("semanticFallback", routing)
        self.assertIn(
            "Only a successful claim authorizes named-model dispatch", routing
        )
        self.assertIn("named model routes only", routing)
        self.assertIn("<skill-root>/scripts/route-capability.py", routing)
        self.assertIn("semanticFallbackReason", routing)
        self.assertIn("agent-type-available", routing)
        self.assertIn(
            "Route, pool, and provider circuits stay open for the\ncurrent task",
            routing,
        )
        self.assertIn("the one recoverable circuit", routing)

    def test_init_writes_private_canonical_state_and_is_idempotent(self) -> None:
        created = self.initialize()
        repeated = self.initialize()
        state = self.load_state()

        self.assertTrue(created["created"])
        self.assertFalse(repeated["created"])
        self.assertEqual(state["revision"], 0)
        self.assertEqual(state["task_id"], self.task_id)
        self.assertEqual(set(state["routes"]), set(self.registry["models"]))
        self.assertEqual(stat.S_IMODE(self.state.stat().st_mode), 0o600)
        self.assertEqual(self.state.read_bytes(), capability.canonical_json(state))

    def test_init_rejects_state_from_another_task(self) -> None:
        self.initialize()

        with self.assertRaisesRegex(capability.CapabilityError, "different task"):
            capability.initialize(self.state, "task-002")

    def test_init_rejects_prior_state_schema(self) -> None:
        self.initialize()
        state = self.load_state()
        state["schema_version"] = capability.STATE_SCHEMA_VERSION - 1
        self.state.write_text(json.dumps(state), encoding="utf-8")

        with self.assertRaisesRegex(capability.CapabilityError, "unsupported.*schema"):
            capability.initialize(self.state, self.task_id)

    def test_cli_runs_claimed_named_model_lifecycle(self) -> None:
        initialized = self.run_cli("init")
        plan = self.run_cli("plan", "--need", "repository discovery")
        claim = self.run_cli(
            "claim",
            "--expected-revision",
            str(plan["revision"]),
            "--need",
            str(plan["need"]),
            "--model",
            "gpt-5-6-luna",
        )
        recorded = self.run_cli(
            "record",
            "--claim-id",
            str(claim["claimId"]),
            "--outcome",
            "success",
        )
        status_value = self.run_cli("status")

        self.assertTrue(initialized["created"])
        self.assertEqual(recorded["revision"], 2)
        self.assertEqual(status_value["activeClaims"], [])
        self.assertEqual(status_value["routes"]["gpt-5-6-luna"], "available")

    def test_directory_sync_rejection_keeps_atomic_state_portable(self) -> None:
        real_fsync = os.fsync

        def portable_fsync(descriptor: int) -> None:
            if stat.S_ISDIR(os.fstat(descriptor).st_mode):
                raise OSError(errno.EINVAL, "directory sync unsupported")
            real_fsync(descriptor)

        with mock.patch.object(capability.os, "fsync", side_effect=portable_fsync):
            result = self.initialize()

        self.assertTrue(result["created"])
        self.assertEqual(self.load_state()["revision"], 0)

    def test_initial_review_plan_requires_preferred_model_choice(self) -> None:
        self.initialize()

        plan = capability.plan_route(self.state, self.task_id, "plan or code review")

        self.assertIsNone(plan["selected"])
        self.assertTrue(plan["selectionRequired"])
        self.assertEqual(
            [candidate["model"] for candidate in plan["preferredCandidates"]],
            ["fable-5-1", "gpt-6-astra"],
        )
        self.assertEqual(
            [candidate["model"] for candidate in plan["candidates"]],
            ["fable-5-1", "gpt-6-astra", "gpt-5-6-sol", "opus-5", "google-opus-4-6"],
        )
        self.assertTrue(all(candidate["probe"] for candidate in plan["candidates"]))
        self.assertEqual(plan["semanticFallback"], "reviewer")
        self.assertIsNone(plan["semanticFallbackReason"])
        self.assertTrue(plan["gatewayEnabled"])
        self.assertEqual(plan["writePolicy"], "read-only")

    def test_claim_reserves_unknown_scopes_and_blocks_repeated_probe(self) -> None:
        self.initialize()

        claim = self.claim("opus-5")
        plan = capability.plan_route(self.state, self.task_id, "plan or code review")
        state = self.load_state()

        self.assertEqual(claim["revision"], 1)
        self.assertEqual(claim["need"], "difficult implementation")
        self.assertEqual(claim["planRevision"], 0)
        self.assertEqual(
            claim["plannedCandidates"],
            ["gpt-5-6-sol", "opus-5", "gpt-5-6-luna", "gemini-3-8-flash"],
        )
        self.assertIsNone(claim["candidateOverride"])
        self.assertEqual(
            set(claim["reservedScopes"]),
            {
                "named-agent-surface",
                "provider:anthropic",
                "pool:anthropic/general",
                "route:opus-5",
            },
        )
        self.assertIsNone(plan["selected"])
        self.assertTrue(plan["claimConflicts"])
        self.assertIsNone(plan["semanticFallback"])
        self.assertEqual(plan["semanticFallbackReason"], "claim-conflict")
        self.assertTrue(
            all(
                blocked["reason"] == "claim:named-agent-surface"
                for blocked in plan["blocked"]
            )
        )
        self.assertEqual(len(state["claims"]), 1)
        stored_claim = next(iter(state["claims"].values()))
        self.assertEqual(stored_claim["need"], "difficult implementation")
        self.assertEqual(stored_claim["plan_revision"], 0)
        self.assertEqual(
            stored_claim["planned_candidates"],
            ["gpt-5-6-sol", "opus-5", "gpt-5-6-luna", "gemini-3-8-flash"],
        )
        self.assertIsNone(stored_claim["candidate_override"])

    def test_non_candidate_requires_categorical_override(self) -> None:
        self.initialize()

        with self.assertRaisesRegex(
            capability.CapabilityError, "current planned candidate set"
        ):
            self.claim(
                "gpt-5-6-terra",
                need="difficult implementation",
                override_reason=None,
            )

        claim = self.claim(
            "gpt-5-6-terra",
            need="difficult implementation",
            override_reason="explicit-model-request",
        )
        stored_claim = next(iter(self.load_state()["claims"].values()))

        self.assertEqual(
            claim["candidateOverride"],
            {"marker": "non-candidate", "reason": "explicit-model-request"},
        )
        self.assertEqual(
            claim["plannedCandidates"],
            ["gpt-5-6-sol", "opus-5", "gpt-5-6-luna", "gemini-3-8-flash"],
        )
        self.assertEqual(stored_claim["candidate_override"], claim["candidateOverride"])

    def test_candidate_rejects_override_marker(self) -> None:
        self.initialize()

        with self.assertRaisesRegex(
            capability.CapabilityError, "not valid for a candidate"
        ):
            self.claim(
                "opus-5",
                need="difficult implementation",
                override_reason="caller-capability-judgment",
            )

    def test_cancel_before_dispatch_releases_claim(self) -> None:
        self.initialize()
        claim = self.claim("opus-5")

        cancelled = capability.cancel_claim(self.state, self.task_id, claim["claimId"])
        plan = capability.plan_route(self.state, self.task_id, "plan or code review")

        self.assertEqual(cancelled["revision"], 2)
        self.assertIsNone(plan["selected"])
        self.assertTrue(plan["selectionRequired"])
        self.assertEqual(self.load_state()["claims"], {})
        repeated = self.claim("opus-5", 2)
        self.assertEqual(repeated["revision"], 3)

    def test_interrupted_dispatch_opens_route_and_releases_claim(self) -> None:
        self.initialize()
        claim = self.claim("opus-5")

        result = capability.record_outcome(
            self.state,
            self.task_id,
            claim["claimId"],
            "dispatch-interrupted",
        )
        plan = capability.plan_route(self.state, self.task_id, "plan or code review")
        state = self.load_state()

        self.assertEqual(result["revision"], 2)
        self.assertIsNone(plan["selected"])
        self.assertTrue(plan["selectionRequired"])
        self.assertEqual(state["routes"]["opus-5"], "open")
        self.assertEqual(state["named_agents"], "unknown")
        self.assertEqual(state["claims"], {})

    def test_independent_claim_outcomes_merge_by_claim_id(self) -> None:
        self.initialize()
        self.complete("gpt-5-6-luna", "success")
        spark = self.claim("gpt-5-3-codex-spark", 2)
        gemini = self.claim("gemini-3-8-flash", 3)

        first = capability.record_outcome(
            self.state, self.task_id, spark["claimId"], "success"
        )
        second = capability.record_outcome(
            self.state, self.task_id, gemini["claimId"], "success"
        )
        state = self.load_state()

        self.assertEqual(first["revision"], 5)
        self.assertEqual(second["revision"], 6)
        self.assertEqual(state["claims"], {})
        self.assertEqual(state["routes"]["gpt-5-3-codex-spark"], "available")
        self.assertEqual(state["routes"]["gemini-3-8-flash"], "available")

    def test_route_failure_blocks_only_one_model(self) -> None:
        self.initialize()
        self.complete("opus-5", "route-unavailable")

        plan = capability.plan_route(self.state, self.task_id, "plan or code review")
        state = self.load_state()

        self.assertIsNone(plan["selected"])
        self.assertTrue(plan["selectionRequired"])
        self.assertEqual(
            plan["blocked"], [{"model": "opus-5", "reason": "route:opus-5"}]
        )
        self.assertEqual(state["providers"]["anthropic"], "available")
        self.assertEqual(state["pools"]["anthropic"]["general"], "unknown")

    def test_quota_failure_blocks_one_pool(self) -> None:
        self.initialize()
        self.complete("opus-5", "quota-exhausted")

        plan = capability.plan_route(self.state, self.task_id, "plan or code review")

        self.assertEqual(plan["selected"], "gpt-6-astra")
        self.assertEqual(
            {blocked["model"] for blocked in plan["blocked"]},
            {"opus-5", "fable-5-1"},
        )
        self.assertTrue(
            all(
                blocked["reason"] == "pool:anthropic/general"
                for blocked in plan["blocked"]
            )
        )

    def test_auth_failure_blocks_one_provider(self) -> None:
        self.initialize()
        self.complete("opus-5", "auth-failure")

        plan = capability.plan_route(self.state, self.task_id, "plan or code review")

        self.assertEqual(plan["selected"], "gpt-6-astra")
        self.assertEqual(
            {blocked["reason"] for blocked in plan["blocked"]},
            {"provider:anthropic"},
        )

    def test_named_agent_failure_returns_semantic_fallback(self) -> None:
        self.initialize()
        self.complete("opus-5", "agent-type-unavailable")

        plan = capability.plan_route(self.state, self.task_id, "implementation")

        self.assertIsNone(plan["selected"])
        self.assertEqual(plan["candidates"], [])
        self.assertFalse(plan["claimConflicts"])
        self.assertEqual(plan["semanticFallback"], "implementer")
        self.assertIsNone(plan["semanticFallbackReason"])
        self.assertEqual(self.load_state()["named_agents"], "open")
        self.assertTrue(
            all(
                blocked["reason"] == "named-agent-surface"
                for blocked in plan["blocked"]
            )
        )

    def test_named_agent_surface_recovers_on_availability_evidence(self) -> None:
        self.initialize()
        self.complete("gpt-5-6-luna", "success")
        blocked_claim = self.claim("opus-5", 2)
        healthy_claim = self.claim("gemini-3-8-flash", 3)

        capability.record_outcome(
            self.state,
            self.task_id,
            blocked_claim["claimId"],
            "agent-type-unavailable",
        )
        opened = capability.plan_route(self.state, self.task_id, "implementation")
        capability.record_outcome(
            self.state,
            self.task_id,
            healthy_claim["claimId"],
            "success",
        )
        recovered = capability.plan_route(self.state, self.task_id, "implementation")
        state = self.load_state()

        self.assertIsNone(opened["selected"])
        self.assertEqual(opened["semanticFallback"], "implementer")
        self.assertEqual(state["named_agents"], "available")
        self.assertIsNone(recovered["selected"])
        self.assertEqual(recovered["blocked"], [])

    def test_explicit_agent_type_available_closes_surface_only(self) -> None:
        self.initialize()
        self.complete("gpt-5-6-luna", "success")
        blocked_claim = self.claim("opus-5", 2)
        healthy_claim = self.claim("gemini-3-8-flash", 3)

        capability.record_outcome(
            self.state,
            self.task_id,
            blocked_claim["claimId"],
            "agent-type-unavailable",
        )
        recorded = capability.record_outcome(
            self.state,
            self.task_id,
            healthy_claim["claimId"],
            "agent-type-available",
        )
        state = self.load_state()

        self.assertEqual(recorded["outcome"], "agent-type-available")
        self.assertEqual(state["named_agents"], "available")
        self.assertEqual(state["routes"]["gemini-3-8-flash"], "unknown")
        self.assertEqual(state["pools"]["google"]["gemini"], "unknown")
        self.assertEqual(state["claims"], {})

    def test_gateway_role_in_exhausted_pool_has_no_semantic_fallback(self) -> None:
        self.initialize()
        self.complete("gpt-5-6-luna", "quota-exhausted")
        capability.ingest_google_telemetry(
            self.state,
            self.task_id,
            2,
            self.google_telemetry("exhausted", "exhausted"),
        )

        plan = capability.plan_route(self.state, self.task_id, "noisy validation")

        self.assertEqual(plan["candidates"], [])
        self.assertFalse(plan["claimConflicts"])
        self.assertIsNone(plan["semanticFallback"])
        self.assertEqual(plan["semanticFallbackReason"], "pool:openai/general")

    def test_native_role_survives_exhausted_gateway_pool(self) -> None:
        self.initialize()
        self.complete("gpt-5-6-luna", "quota-exhausted")
        capability.ingest_google_telemetry(
            self.state,
            self.task_id,
            2,
            self.google_telemetry("exhausted", "exhausted"),
        )

        plan = capability.plan_route(
            self.state, self.task_id, "noisy validation", False
        )

        self.assertEqual(plan["candidates"], [])
        self.assertFalse(plan["gatewayEnabled"])
        self.assertEqual(plan["semanticFallback"], "test-runner")
        self.assertIsNone(plan["semanticFallbackReason"])

    def test_gateway_role_in_healthy_pool_keeps_semantic_fallback(self) -> None:
        self.initialize()
        self.complete("gpt-oss-120b", "agent-type-unavailable")

        plan = capability.plan_route(self.state, self.task_id, "noisy validation")
        state = self.load_state()

        self.assertEqual(plan["candidates"], [])
        self.assertEqual(state["pools"]["google"]["claude-gpt"], "unknown")
        self.assertEqual(plan["semanticFallback"], "test-runner")
        self.assertIsNone(plan["semanticFallbackReason"])

    def test_success_marks_exact_route_pool_provider_and_surface(self) -> None:
        self.initialize()
        result = self.complete("gpt-5-6-luna", "success")
        state = self.load_state()

        self.assertEqual(result["revision"], 2)
        self.assertEqual(state["named_agents"], "available")
        self.assertEqual(state["providers"]["openai"], "available")
        self.assertEqual(state["pools"]["openai"]["general"], "available")
        self.assertEqual(state["routes"]["gpt-5-6-luna"], "available")
        self.assertEqual(state["routes"]["gpt-5-6-sol"], "unknown")

    def test_open_pool_is_sticky_after_available_telemetry(self) -> None:
        self.initialize()
        capability.ingest_google_telemetry(
            self.state,
            self.task_id,
            0,
            self.google_telemetry("exhausted", "available"),
        )
        result = capability.ingest_google_telemetry(
            self.state,
            self.task_id,
            1,
            self.google_telemetry("available", "available"),
        )

        state = self.load_state()

        self.assertFalse(result["changed"])
        self.assertEqual(result["revision"], 1)
        self.assertEqual(state["pools"]["google"]["claude-gpt"], "open")

    def test_stale_revision_is_rejected_without_mutation(self) -> None:
        self.initialize()
        self.claim("gpt-5-6-luna")
        before = self.state.read_bytes()

        with self.assertRaisesRegex(
            capability.CapabilityError, "stale capability revision"
        ):
            capability.claim_route(
                self.state,
                self.task_id,
                0,
                "obvious lookup or mechanical one-file edit",
                "gpt-5-3-codex-spark",
            )

        self.assertEqual(self.state.read_bytes(), before)

    def test_concurrent_cli_claims_allow_one_probe(self) -> None:
        self.initialize()
        command = [
            sys.executable,
            "-B",
            str(SCRIPT),
            "--state",
            str(self.state),
            "--task-id",
            self.task_id,
            "claim",
            "--expected-revision",
            "0",
            "--need",
            "plan or code review",
            "--model",
            "opus-5",
        ]
        environment = os.environ.copy()
        environment["PYTHONDONTWRITEBYTECODE"] = "1"

        processes = [
            subprocess.Popen(
                command,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
                env=environment,
            )
            for _ in range(2)
        ]
        results = [process.communicate(timeout=20) for process in processes]

        self.assertEqual(sorted(process.returncode for process in processes), [0, 1])
        success = next(
            json.loads(stdout)
            for process, (stdout, _stderr) in zip(processes, results, strict=True)
            if process.returncode == 0
        )
        failure = next(
            json.loads(stderr)
            for process, (_stdout, stderr) in zip(processes, results, strict=True)
            if process.returncode == 1
        )
        self.assertEqual(success["revision"], 1)
        self.assertIn("stale capability revision", failure["error"])
        self.assertEqual(len(self.load_state()["claims"]), 1)

    def test_boolean_revision_is_rejected(self) -> None:
        self.initialize()

        with self.assertRaisesRegex(capability.CapabilityError, "non-negative integer"):
            capability.claim_route(
                self.state,
                self.task_id,
                True,
                "repository discovery",
                "gpt-5-6-luna",
            )

    def test_google_telemetry_opens_only_exhausted_pool(self) -> None:
        self.initialize()
        telemetry = self.google_telemetry("exhausted", "available")
        telemetry["pools"]["claude-gpt"]["usedPercent"] = 100
        with self.assertRaisesRegex(capability.CapabilityError, "unknown or missing"):
            capability.ingest_google_telemetry(self.state, self.task_id, 0, telemetry)

        telemetry["pools"]["claude-gpt"].pop("usedPercent")
        result = capability.ingest_google_telemetry(
            self.state, self.task_id, 0, telemetry
        )
        state = self.load_state()

        self.assertEqual(result["revision"], 1)
        self.assertEqual(state["providers"]["google"], "available")
        self.assertEqual(state["pools"]["google"]["claude-gpt"], "open")
        self.assertEqual(state["pools"]["google"]["gemini"], "available")
        self.assertNotIn("usedPercent", self.state.read_text(encoding="utf-8"))

    def test_unknown_google_telemetry_does_not_mutate_state(self) -> None:
        self.initialize()
        before = self.state.read_bytes()

        result = capability.ingest_google_telemetry(
            self.state,
            self.task_id,
            0,
            {"provider": "google", "status": "unknown", "reason": "quota-data-missing"},
        )

        self.assertFalse(result["changed"])
        self.assertEqual(result["revision"], 0)
        self.assertEqual(self.state.read_bytes(), before)

    def test_google_telemetry_rejects_wrong_model_membership(self) -> None:
        self.initialize()
        telemetry = self.google_telemetry()
        telemetry["pools"]["gemini"]["models"].pop()

        with self.assertRaisesRegex(capability.CapabilityError, "wrong model set"):
            capability.ingest_google_telemetry(self.state, self.task_id, 0, telemetry)

    @unittest.skipUnless(hasattr(os, "symlink"), "symlinks are unavailable")
    def test_state_and_lock_symlinks_are_rejected(self) -> None:
        target = self.root / "target.json"
        target.write_text("{}", encoding="utf-8")
        self.state.symlink_to(target)

        with self.assertRaisesRegex(capability.CapabilityError, "regular file"):
            self.initialize()

        self.state.unlink()
        lock = self.state.with_name(f"{self.state.name}.lock")
        lock.unlink()
        lock.symlink_to(target)
        with self.assertRaisesRegex(capability.CapabilityError, "state lock"):
            self.initialize()

    def test_tampered_state_fails_closed(self) -> None:
        self.initialize()
        state = self.load_state()
        state["transcript"] = "must not persist"
        self.state.write_text(json.dumps(state), encoding="utf-8")

        with self.assertRaisesRegex(capability.CapabilityError, "unknown or missing"):
            capability.plan_route(self.state, self.task_id, "implementation")

    def test_non_text_circuit_state_fails_closed(self) -> None:
        self.initialize()
        state = self.load_state()
        state["providers"]["openai"] = []
        self.state.write_text(json.dumps(state), encoding="utf-8")

        with self.assertRaisesRegex(
            capability.CapabilityError, "invalid circuit state"
        ):
            capability.plan_route(self.state, self.task_id, "implementation")

    def test_tampered_claim_cannot_omit_unknown_scope(self) -> None:
        self.initialize()
        self.claim("opus-5")
        state = self.load_state()
        claim = next(iter(state["claims"].values()))
        claim["scopes"].remove("provider:anthropic")
        self.state.write_text(json.dumps(state), encoding="utf-8")

        with self.assertRaisesRegex(capability.CapabilityError, "omits an unknown"):
            capability.plan_route(self.state, self.task_id, "implementation")

    def test_tampered_claim_binding_fails_closed(self) -> None:
        self.initialize()
        self.claim("opus-5")
        state = self.load_state()
        claim = next(iter(state["claims"].values()))
        claim["planned_candidates"] = ["gpt-5-6-luna"]
        self.state.write_text(json.dumps(state), encoding="utf-8")

        with self.assertRaisesRegex(capability.CapabilityError, "not a planned"):
            capability.plan_route(self.state, self.task_id, "implementation")

        claim["planned_candidates"] = [
            "opus-5",
            "gpt-5-6-luna",
            "gemini-3-8-flash",
        ]
        claim["candidate_override"] = {
            "marker": "non-candidate",
            "reason": [],
        }
        self.state.write_text(json.dumps(state), encoding="utf-8")

        with self.assertRaisesRegex(capability.CapabilityError, "candidate override"):
            capability.plan_route(self.state, self.task_id, "implementation")

    @unittest.skipUnless(hasattr(os, "mkfifo"), "FIFOs are unavailable")
    def test_fifo_state_is_rejected_without_blocking(self) -> None:
        os.mkfifo(self.state)

        with self.assertRaisesRegex(capability.CapabilityError, "regular file"):
            self.initialize()

    @unittest.skipUnless(
        shutil.which("bash") and shutil.which("jq"), "bash and jq are required"
    )
    def test_google_quota_script_derives_models_and_emits_categories_only(self) -> None:
        bin_dir = self.root / "bin"
        bin_dir.mkdir()
        codexbar = bin_dir / "codexbar"
        payload = [
            {
                "usage": {
                    "extraRateWindows": [
                        {
                            "id": "antigravity-quota-summary-3p-test",
                            "window": {"usedPercent": 100},
                        },
                        {
                            "id": "antigravity-quota-summary-gemini-test",
                            "window": {"usedPercent": 25},
                        },
                    ]
                }
            }
        ]
        codexbar.write_text(
            "#!/bin/sh\nprintf '%s\\n' " + repr(json.dumps(payload)) + "\n",
            encoding="utf-8",
        )
        codexbar.chmod(0o755)
        environment = os.environ.copy()
        environment["PATH"] = f"{bin_dir}{os.pathsep}{environment['PATH']}"

        result = subprocess.run(
            [str(shutil.which("bash")), str(GOOGLE_QUOTA)],
            check=True,
            capture_output=True,
            text=True,
            env=environment,
        )
        report = json.loads(result.stdout)

        self.assertEqual(report["pools"]["claude-gpt"]["status"], "exhausted")
        self.assertEqual(report["pools"]["gemini"]["status"], "available")
        self.assertEqual(
            report["pools"]["claude-gpt"]["models"],
            self.pool_models("claude-gpt"),
        )
        self.assertNotIn("usedPercent", result.stdout)
        self.assertNotIn("resetsAt", result.stdout)


if __name__ == "__main__":
    unittest.main()
