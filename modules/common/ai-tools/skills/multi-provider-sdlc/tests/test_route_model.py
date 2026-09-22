from __future__ import annotations

import importlib.util
import json
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(__file__).resolve().parents[1] / "scripts" / "route-model.py"
SPEC = importlib.util.spec_from_file_location("route_model", SCRIPT)
assert SPEC is not None and SPEC.loader is not None
resolver = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(resolver)


class RouteModelTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.state = Path(self.temporary.name) / "capability.json"
        self.capability = resolver.capability

    def request(self, **changes: object) -> dict:
        return {
            "task_type": "implementation",
            "provider": "codex",
            "gateway": False,
        } | changes

    def state_request(self, **changes: object) -> dict:
        self.capability.initialize(self.state, "task-001")
        return (
            self.request(
                gateway=True, state={"path": str(self.state), "task_id": "task-001"}
            )
            | changes
        )

    def test_native_profiles_match_each_provider(self) -> None:
        expected = {
            "codex": "gpt-6-sol",
            "opencode": "openai/gpt-6-sol",
            "claude": "opus",
            "copilot": "claude-opus-4.6",
        }
        for provider, model in expected.items():
            result = resolver.resolve(self.request(provider=provider))
            self.assertEqual(result["agent_type"], "implementer")
            self.assertEqual(result["model"], model)
            self.assertEqual(result["status"], "ready")
        self.assertEqual(resolver.resolve(self.request())["reasoning_effort"], "medium")

    def test_gateway_names_match_provider_projections(self) -> None:
        for provider in ("codex", "claude", "opencode"):
            result = resolver.resolve(self.request(provider=provider, gateway=True))
            self.assertEqual(result["agent_type"], "gpt-6-sol")
            self.assertEqual(
                result["model"],
                ("cliproxyapi/" if provider == "opencode" else "") + "claude-gpt-6-sol",
            )
            self.assertEqual(
                result["reasoning_effort"], "high" if provider == "codex" else None
            )

    @unittest.skipUnless(shutil.which("nix"), "nix is not installed")
    def test_dispatch_matches_generated_codex_workers(self) -> None:
        from test_model_routing import ModelRoutingTests

        registry, _ = self.capability.load_registry_context()
        for gateway in (False, True):
            workers = json.loads(
                ModelRoutingTests._nix_eval(
                    ModelRoutingTests._provider_projection_expression(gateway)
                )
            )["codex"]
            for route in registry["task_routes"]:
                with self.subTest(gateway=gateway, task=route["need"]):
                    result = resolver.resolve(
                        self.request(task_type=route["need"], gateway=gateway)
                    )
                    worker = workers[result["agent_type"]]
                    self.assertEqual(result["model"], worker["model"])
                    self.assertEqual(
                        result["reasoning_effort"], worker.get("model_reasoning_effort")
                    )

    def test_luna_owns_former_spark_tasks(self) -> None:
        for task in (
            "obvious lookup or mechanical one-file edit",
            "focused validation",
        ):
            for gateway in (False, True):
                result = resolver.resolve(self.request(task_type=task, gateway=gateway))
                self.assertTrue(result["model"].endswith("gpt-6-luna"))

    def test_equal_preferences_use_canonical_order(self) -> None:
        request = self.request(task_type="plan or code review", gateway=True)
        result = resolver.resolve(request)
        self.assertEqual(result, resolver.resolve(request))
        self.assertEqual(result["model_id"], "fable-5-1")
        self.assertEqual(result["write_policy"], "read-only")

    def test_subscription_constraint_selects_review_seat(self) -> None:
        result = resolver.resolve(
            self.request(
                task_type="plan or code review", gateway=True, subscription="openai"
            )
        )
        self.assertEqual(result["model_id"], "gpt-6-astra")
        self.assertEqual(result["reasoning_effort"], "low")

    def test_unknown_input_fails_closed(self) -> None:
        requests = [
            None,
            [],
            {},
            self.request(task_type="invented"),
            self.request(provider="invented"),
            self.request(gateway="true"),
            self.request(extra=True),
            self.request(gateway=True, provider="copilot"),
            self.request(subscription="openai"),
            self.request(gateway=True, subscription="invented"),
            self.request(gateway=True, state={}),
            self.request(gateway=True, state={"path": [], "task_id": "task-001"}),
            self.request(gateway=True, state={"path": "state", "task_id": "bad id"}),
        ]
        for request in requests:
            with self.subTest(request=request), self.assertRaises(ValueError):
                resolver.resolve(request)

    def test_stateful_resolution_is_read_only_and_requires_claim(self) -> None:
        request = self.state_request()
        before = self.state.read_bytes()
        result = resolver.resolve(request)
        self.assertEqual(self.state.read_bytes(), before)
        self.assertEqual(result["status"], "claim_required")
        claim = subprocess.run(
            result["claim_argv"], capture_output=True, text=True, check=True
        )
        self.assertEqual(json.loads(claim.stdout)["model"], "gpt-6-sol")
        blocked = resolver.resolve(request)
        self.assertEqual(blocked["status"], "blocked")
        self.assertEqual(blocked["reason"], "claim-conflict")

    def test_stale_claim_cannot_dispatch(self) -> None:
        request = self.state_request()
        result = resolver.resolve(request)
        self.capability.claim_route(
            self.state, "task-001", 0, "implementation", "gpt-6-sol"
        )
        attempt = subprocess.run(
            result["claim_argv"], capture_output=True, text=True, check=False
        )
        self.assertNotEqual(attempt.returncode, 0)
        self.assertIn("stale capability revision", attempt.stderr)

    def test_quota_fallback_skips_every_model_in_open_pool(self) -> None:
        request = self.state_request()
        claim = self.capability.claim_route(
            self.state, "task-001", 0, "implementation", "gpt-6-sol"
        )
        self.capability.record_outcome(
            self.state, "task-001", claim["claimId"], "quota-exhausted"
        )
        result = resolver.resolve(request)
        self.assertEqual(result["model_id"], "gemini-3-8-flash")
        blocked = resolver.resolve(request | {"subscription": "openai"})
        self.assertEqual(blocked["status"], "blocked")

    def test_named_surface_failure_returns_semantic_worker(self) -> None:
        request = self.state_request()
        claim = self.capability.claim_route(
            self.state, "task-001", 0, "implementation", "gpt-6-sol"
        )
        self.capability.record_outcome(
            self.state, "task-001", claim["claimId"], "agent-type-unavailable"
        )
        result = resolver.resolve(request)
        self.assertEqual(result["agent_type"], "implementer")
        self.assertEqual(result["model"], "gpt-6-sol")
        self.assertEqual(result["selection_basis"], "semantic-fallback")
        self.assertNotIn("claim_argv", result)

    def test_state_task_mismatch_is_rejected(self) -> None:
        request = self.state_request()
        request["state"]["task_id"] = "different-task"
        with self.assertRaises(ValueError):
            resolver.resolve(request)

    def test_cli_schema_and_bounded_json_output(self) -> None:
        process = subprocess.run(
            [sys.executable, str(SCRIPT), "--schema"],
            capture_output=True,
            text=True,
            check=True,
        )
        schema = json.loads(process.stdout)
        registry, _ = self.capability.load_registry_context()
        self.assertEqual(
            schema["properties"]["task_type"]["enum"],
            [route["need"] for route in registry["task_routes"]],
        )
        process = subprocess.run(
            [sys.executable, str(SCRIPT)],
            input=json.dumps(self.request()),
            capture_output=True,
            text=True,
            check=True,
        )
        self.assertEqual(process.stderr, "")
        self.assertEqual(json.loads(process.stdout)["model"], "gpt-6-sol")
        self.assertLess(len(process.stdout), 1024)

    def test_skill_entry_point_is_script_only(self) -> None:
        skill = (SCRIPT.parents[1] / "SKILL.md").read_text()
        self.assertIn("scripts/route-model.py", skill)
        self.assertIn("--schema", skill)
        self.assertNotIn("references/", skill)
        self.assertNotIn("model-routing.json", skill)
        self.assertLessEqual(len(skill.splitlines()), 25)

    def test_cli_rejects_duplicate_keys_and_oversized_input(self) -> None:
        for value in (
            '{"task_type":"implementation","task_type":"review"}',
            " " * (resolver.MAX_REQUEST_BYTES + 1),
        ):
            process = subprocess.run(
                [sys.executable, str(SCRIPT)],
                input=value,
                check=False,
                capture_output=True,
                text=True,
            )
            self.assertEqual(process.returncode, 2)
            self.assertEqual(process.stdout, "")
            self.assertIn("error", json.loads(process.stderr))


if __name__ == "__main__":
    unittest.main()
