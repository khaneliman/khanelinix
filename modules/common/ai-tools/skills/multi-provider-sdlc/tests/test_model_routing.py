from __future__ import annotations

import copy
import importlib.util
import sys
import unittest
from pathlib import Path

SKILL_ROOT = Path(__file__).resolve().parents[1]
SCRIPT = SKILL_ROOT / "scripts" / "render-model-routes.py"
SPEC = importlib.util.spec_from_file_location("render_model_routes", SCRIPT)
assert SPEC is not None and SPEC.loader is not None
routes = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = routes
SPEC.loader.exec_module(routes)


class ModelRoutingTests(unittest.TestCase):
    def setUp(self) -> None:
        self.registry = routes.load_registry()

    def test_generated_reference_matches_registry(self) -> None:
        reference = routes.REFERENCE_PATH.read_text(encoding="utf-8")

        self.assertEqual(
            reference,
            routes.render_reference(self.registry, reference),
        )

    def test_every_model_belongs_to_one_subscription(self) -> None:
        members = [
            model
            for subscription in self.registry["subscriptions"].values()
            for model in subscription["model_agents"]
        ]

        self.assertEqual(len(members), len(set(members)))
        self.assertEqual(set(members), set(self.registry["models"]))

    def test_every_route_reference_resolves(self) -> None:
        models = self.registry["models"]
        roles = self.registry["semantic_roles"]

        for role in roles.values():
            for model in role["gateway"].values():
                self.assertIn(model, models)
        for route in self.registry["task_routes"]:
            self.assertIn(route["semantic_role"], roles)
            self.assertIn(route["primary"], models)
            for model in route["fallbacks"]:
                self.assertIn(model, models)

    def test_aliases_are_unique_and_claude_visible(self) -> None:
        aliases = [model["gateway_alias"] for model in self.registry["models"].values()]

        self.assertEqual(len(aliases), len(set(aliases)))
        self.assertTrue(
            all(alias.startswith(("claude", "anthropic")) for alias in aliases)
        )

    def test_invalid_model_reference_is_rejected(self) -> None:
        invalid = copy.deepcopy(self.registry)
        invalid["task_routes"][0]["primary"] = "missing-model"

        with self.assertRaisesRegex(routes.RoutingError, "unknown model references"):
            routes.validate_registry(invalid)

    def test_boolean_schema_version_is_rejected(self) -> None:
        invalid = copy.deepcopy(self.registry)
        invalid["schema_version"] = True

        with self.assertRaisesRegex(routes.RoutingError, "schema_version"):
            routes.validate_registry(invalid)

    def test_missing_published_alias_is_rejected(self) -> None:
        invalid = copy.deepcopy(self.registry)
        invalid["cliproxy_alias_order"].pop()

        with self.assertRaisesRegex(routes.RoutingError, "every published model"):
            routes.validate_registry(invalid)

    def test_unknown_quota_pool_is_rejected(self) -> None:
        invalid = copy.deepcopy(self.registry)
        invalid["models"]["opus-5"]["quota_pool"] = "missing"

        with self.assertRaisesRegex(routes.RoutingError, "unknown quota pool"):
            routes.validate_registry(invalid)

    def test_cross_provider_default_is_rejected(self) -> None:
        invalid = copy.deepcopy(self.registry)
        invalid["gateway_defaults"]["codex"] = "opus-5"

        with self.assertRaisesRegex(routes.RoutingError, "wrong provider: codex"):
            routes.validate_registry(invalid)

    def test_cross_provider_model_is_rejected(self) -> None:
        invalid = copy.deepcopy(self.registry)
        invalid["models"]["gpt-5-6-luna"]["upstream_provider"] = "antigravity"

        with self.assertRaisesRegex(routes.RoutingError, "gpt-5-6-luna"):
            routes.validate_registry(invalid)

    def test_cross_provider_native_model_is_rejected(self) -> None:
        invalid = copy.deepcopy(self.registry)
        invalid["semantic_roles"]["reviewer"]["native"]["codex"] = "claude-opus-5"

        with self.assertRaisesRegex(routes.RoutingError, "cross-provider native"):
            routes.validate_registry(invalid)

    def test_cross_provider_deliberation_seat_is_rejected(self) -> None:
        invalid = copy.deepcopy(self.registry)
        invalid["deliberation"]["google"] = "opus-5"

        with self.assertRaisesRegex(routes.RoutingError, "wrong provider: google"):
            routes.validate_registry(invalid)

    def test_unsafe_markdown_table_cell_is_rejected(self) -> None:
        invalid = copy.deepcopy(self.registry)
        invalid["task_routes"][0]["need"] = "lookup | edit"

        with self.assertRaisesRegex(routes.RoutingError, "Markdown table syntax"):
            routes.validate_registry(invalid)

    def test_unknown_write_policy_is_rejected(self) -> None:
        invalid = copy.deepcopy(self.registry)
        invalid["task_routes"][0]["write_policy"] = "anything goes"

        with self.assertRaisesRegex(routes.RoutingError, "invalid write policy"):
            routes.validate_registry(invalid)

    def test_unknown_subscription_is_rejected(self) -> None:
        invalid = copy.deepcopy(self.registry)
        invalid["subscriptions"]["other"] = {
            "label": "Other",
            "model_agents": [],
        }
        invalid["subscription_order"].append("other")
        invalid["quota_pools"]["other"] = ["general"]

        with self.assertRaisesRegex(routes.RoutingError, "unsupported provider"):
            routes.validate_registry(invalid)

    def test_generated_marker_cell_is_rejected(self) -> None:
        invalid = copy.deepcopy(self.registry)
        invalid["subscriptions"]["openai"]["label"] = routes.ROUTES_BEGIN

        with self.assertRaisesRegex(routes.RoutingError, "Markdown table syntax"):
            routes.validate_registry(invalid)

    def test_unknown_schema_field_is_rejected(self) -> None:
        invalid = copy.deepcopy(self.registry)
        invalid["models"]["opus-5"]["provider_typo"] = "claude"

        with self.assertRaisesRegex(routes.RoutingError, "unknown or missing"):
            routes.validate_registry(invalid)

    def test_invalid_effort_is_rejected(self) -> None:
        invalid = copy.deepcopy(self.registry)
        invalid["semantic_roles"]["reviewer"]["reasoning_effort"]["codex"] = "banana"

        with self.assertRaisesRegex(routes.RoutingError, "invalid effort"):
            routes.validate_registry(invalid)

    def test_reversed_section_markers_are_rejected(self) -> None:
        text = f"{routes.SUBSCRIPTIONS_END}\n{routes.SUBSCRIPTIONS_BEGIN}\n"

        with self.assertRaisesRegex(routes.RoutingError, "expected one"):
            routes.replace_section(
                text,
                routes.SUBSCRIPTIONS_BEGIN,
                routes.SUBSCRIPTIONS_END,
                "body",
            )


if __name__ == "__main__":
    unittest.main()
