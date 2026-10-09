from __future__ import annotations

import copy
import json
import subprocess
import unittest

import test_route_model as route_tests

resolver = route_tests.resolver


def provider(instance: str, driver: str, models: list[str]) -> dict:
    return {
        "providerInstanceId": instance,
        "driverKind": driver,
        "canRunChildTask": True,
        "canRunCrossProviderChildTask": True,
        "models": [
            {
                "id": model,
                "options": [
                    {
                        "id": "reasoningEffort",
                        "type": "select",
                        "options": [
                            {"id": effort} for effort in ("low", "medium", "high")
                        ],
                    }
                ]
                if driver == "codex"
                else [],
            }
            for model in models
        ],
    }


class NativeDispatchTests(unittest.TestCase):
    setUp = route_tests.RouteModelTests.setUp
    request = route_tests.RouteModelTests.request
    state_request = route_tests.RouteModelTests.state_request

    def catalog(self) -> dict:
        return {
            "providers": [
                provider(
                    "work-openai", "codex", ["gpt-6.1-sol", "gpt-6-luna", "gpt-6-astra"]
                ),
                provider(
                    "work-anthropic",
                    "claudeAgent",
                    ["claude-opus-5-5", "claude-haiku-5-5"],
                ),
                provider("work-google", "antigravity", ["gemini-3.8-flash-high"]),
            ]
        }

    def t3_request(self, **changes: object) -> dict:
        return self.request(**({"capabilities": self.catalog()} | changes))

    def claim_result(self, result: dict) -> dict:
        process = subprocess.run(
            result["claim_argv"], capture_output=True, text=True, check=True
        )
        return json.loads(process.stdout)

    def test_t3_targets_live_instances_not_named_agents(self) -> None:
        review = resolver.resolve(self.t3_request(task_type="plan or code review"))
        self.assertEqual(
            review["target"],
            {"providerInstanceId": "work-anthropic", "model": "claude-opus-5-5"},
        )
        self.assertEqual(review["next_action"], "delegate_task")
        self.assertNotIn("agent_type", review)
        self.assertEqual(review["write_policy"], "read-only")
        implementation = resolver.resolve(self.t3_request())
        self.assertEqual(implementation["target"]["model"], "gpt-6.1-sol")
        self.assertEqual(
            implementation["target"]["options"], {"reasoningEffort": "medium"}
        )
        astra = resolver.resolve(
            self.t3_request(task_type="plan or code review", subscription="openai")
        )
        self.assertEqual(astra["target"]["options"], {"reasoningEffort": "high"})

    def test_google_native_route_and_parent_are_supported(self) -> None:
        result = resolver.resolve(
            self.t3_request(provider="antigravity", task_type="multimodal analysis")
        )
        self.assertEqual(
            result["target"],
            {"providerInstanceId": "work-google", "model": "gemini-3.8-flash-high"},
        )
        self.assertIsNone(result["reasoning_effort"])

    def test_catalog_rejects_unavailable_and_wrong_provider_routes(self) -> None:
        catalog = self.catalog()
        catalog["providers"][0]["canRunChildTask"] = False
        result = resolver.resolve(self.t3_request(capabilities=catalog))
        self.assertEqual(result["target"]["providerInstanceId"], "work-anthropic")
        catalog["providers"][1]["canRunCrossProviderChildTask"] = False
        catalog["providers"][2]["models"] = []
        result = resolver.resolve(self.t3_request(capabilities=catalog))
        self.assertEqual(result["status"], "blocked")
        catalog = {
            "providers": [
                provider("wrong", "antigravity", ["claude-opus-5-5", "gpt-6.1-sol"])
            ]
        }
        self.assertEqual(
            resolver.resolve(self.t3_request(capabilities=catalog))["status"], "blocked"
        )

    def test_gateway_alias_and_unsupported_effort_are_not_guessed(self) -> None:
        catalog = self.catalog()
        catalog["providers"][0]["models"][0]["id"] = "claude-gpt-6.1-sol"
        self.assertEqual(
            resolver.resolve(self.t3_request(capabilities=catalog))["model_id"],
            "opus-5-5",
        )
        catalog = self.catalog()
        catalog["providers"][0]["models"][0]["options"][0]["options"] = [{"id": "low"}]
        self.assertEqual(
            resolver.resolve(self.t3_request(capabilities=catalog))["model_id"],
            "opus-5-5",
        )

    def test_multiple_accounts_require_explicit_catalog_narrowing(self) -> None:
        catalog = self.catalog()
        extra = copy.deepcopy(catalog["providers"][0])
        extra["providerInstanceId"] = "personal-openai"
        catalog["providers"].append(extra)
        result = resolver.resolve(self.t3_request(capabilities=catalog))
        self.assertEqual(result["status"], "blocked")
        self.assertIn("intended account", result["reason"])

    def test_native_profile_can_claim_and_reuse_quota_evidence(self) -> None:
        request = self.state_request(gateway=False, subscription="openai")
        before = self.state.read_bytes()
        result = resolver.resolve(request)
        self.assertEqual(result["agent_type"], "implementer")
        self.assertEqual(result["status"], "claim_required")
        self.assertNotIn("agent-type-unavailable", result["outcomes"])
        self.assertEqual(self.state.read_bytes(), before)
        claim = self.claim_result(result)
        self.assertNotIn("named-agent-surface", claim["reservedScopes"])
        self.capability.record_outcome(
            self.state, "task-001", claim["claimId"], "quota-exhausted"
        )
        blocked = resolver.resolve(request)
        self.assertEqual(blocked["reason"], "pool:openai/general")
        fallback = resolver.resolve(
            request | {"capabilities": self.catalog(), "subscription": "anthropic"}
        )
        self.assertEqual(fallback["target"]["providerInstanceId"], "work-anthropic")
        self.assertEqual(fallback["status"], "claim_required")

    def test_t3_does_not_depend_on_or_recover_local_named_surface(self) -> None:
        request = self.state_request(gateway=False, capabilities=self.catalog())
        claim = self.capability.claim_route(
            self.state, "task-001", 0, "implementation", "gpt-6-1-sol"
        )
        self.capability.record_outcome(
            self.state, "task-001", claim["claimId"], "agent-type-unavailable"
        )
        result = resolver.resolve(request)
        self.assertEqual(result["target"]["model"], "gpt-6.1-sol")
        native_claim = self.claim_result(result)
        self.capability.record_outcome(
            self.state, "task-001", native_claim["claimId"], "success"
        )
        state = json.loads(self.state.read_text())
        self.assertEqual(state["named_agents"], "open")
        self.assertEqual(state["providers"]["openai"], "available")

    def test_native_claim_checks_conflicts_stale_revisions_and_outcomes(self) -> None:
        request = self.state_request(
            gateway=False, capabilities=self.catalog(), subscription="openai"
        )
        result = resolver.resolve(request)
        claim = self.claim_result(result)
        blocked = resolver.resolve(request)
        self.assertEqual(blocked["status"], "blocked")
        stale = subprocess.run(
            result["claim_argv"], capture_output=True, text=True, check=False
        )
        self.assertNotEqual(stale.returncode, 0)
        before = self.state.read_bytes()
        with self.assertRaisesRegex(ValueError, "no named-agent"):
            self.capability.record_outcome(
                self.state, "task-001", claim["claimId"], "agent-type-unavailable"
            )
        self.assertEqual(self.state.read_bytes(), before)

    def test_local_profile_cannot_pretend_to_switch_subscription(self) -> None:
        result = resolver.resolve(self.request(subscription="anthropic"))
        self.assertEqual(result["status"], "blocked")
        self.assertIn("requires T3", result["reason"])

    def test_capabilities_validation_fails_closed(self) -> None:
        for catalog in (None, {}, {"providers": [{}]}, {"providers": "not-a-list"}):
            with self.subTest(catalog=catalog), self.assertRaises(ValueError):
                resolver.resolve(self.t3_request(capabilities=catalog))
        with self.assertRaises(ValueError):
            resolver.resolve(self.t3_request(gateway=True))
        catalog = self.catalog()
        catalog["providers"][0]["models"][0]["options"] = [
            {"id": "reasoningEffort", "type": "select", "options": ["medium"]}
        ]
        with self.assertRaises(ValueError):
            resolver.resolve(self.t3_request(capabilities=catalog))
