from __future__ import annotations

import copy
import hashlib
import importlib.util
import json
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

SKILL_ROOT = Path(__file__).resolve().parents[1]
AI_TOOLS_ROOT = SKILL_ROOT.parents[1]
REPO_ROOT = AI_TOOLS_ROOT.parents[2]
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
            for model in [*route["preferred"], *route["fallbacks"]]:
                self.assertIn(model, models)

    def test_review_and_implementation_preferences_are_canonical(self) -> None:
        routes = {route["need"]: route for route in self.registry["task_routes"]}

        self.assertEqual(
            routes["plan or code review"]["preferred"],
            ["fable-5-1", "gpt-5-6-sol"],
        )
        self.assertEqual(
            routes["plan or code review"]["fallbacks"],
            ["opus-5", "google-opus-4-6"],
        )
        self.assertEqual(
            self.registry["semantic_roles"]["reviewer"]["gateway"]["claude"],
            "fable-5-1",
        )
        self.assertFalse(self.registry["models"]["fable-5-1"]["write"])
        self.assertFalse(self.registry["models"]["fable-5-1"]["workspace_write"])
        self.assertEqual(
            routes["implementation"]["fallbacks"],
            ["gpt-5-6-luna", "gemini-3-8-flash"],
        )
        self.assertTrue(self.registry["models"]["gemini-3-8-flash"]["write"])

    def test_aliases_are_unique_and_claude_visible(self) -> None:
        aliases = [model["gateway_alias"] for model in self.registry["models"].values()]

        self.assertEqual(len(aliases), len(set(aliases)))
        self.assertTrue(
            all(alias.startswith(("claude", "anthropic")) for alias in aliases)
        )

    def test_fable_5_1_uses_hyphenated_gateway_id(self) -> None:
        fable = self.registry["models"]["fable-5-1"]

        self.assertEqual(fable["upstream_model"], "claude-fable-5-1")
        self.assertEqual(fable["gateway_alias"], "claude-fable-5-1")

    def test_invalid_model_reference_is_rejected(self) -> None:
        invalid = copy.deepcopy(self.registry)
        invalid["task_routes"][0]["preferred"][0] = "missing-model"

        with self.assertRaisesRegex(routes.RoutingError, "unknown model references"):
            routes.validate_registry(invalid)

    def test_empty_preferred_route_is_rejected(self) -> None:
        invalid = copy.deepcopy(self.registry)
        invalid["task_routes"][0]["preferred"] = []

        with self.assertRaisesRegex(routes.RoutingError, "preferred models"):
            routes.validate_registry(invalid)

    def test_duplicate_route_model_is_rejected(self) -> None:
        invalid = copy.deepcopy(self.registry)
        invalid["task_routes"][0]["fallbacks"].append(
            invalid["task_routes"][0]["preferred"][0]
        )

        with self.assertRaisesRegex(routes.RoutingError, "models must be unique"):
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

    def test_policy_control_characters_are_rejected(self) -> None:
        cases = {
            "alias": lambda value: value["models"]["opus-5"].__setitem__(
                "gateway_alias", "claude-opus-5\nmodel: injected"
            ),
            "description": lambda value: value["models"]["opus-5"].__setitem__(
                "description", "worker\tdescription"
            ),
            "model ID": lambda value: value["models"].__setitem__(
                "model\rID", value["models"].pop("opus-5")
            ),
            "provider ID": lambda value: value["subscriptions"].__setitem__(
                "openai\nprovider", value["subscriptions"].pop("openai")
            ),
            "rendered model ID": lambda value: value["semantic_roles"]["reviewer"][
                "native"
            ].__setitem__("codex", "gpt-5.6-sol\nname = injected"),
        }

        for label, mutate in cases.items():
            with self.subTest(label=label):
                invalid = copy.deepcopy(self.registry)
                mutate(invalid)
                with self.assertRaisesRegex(routes.RoutingError, "control characters"):
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

    def test_nix_consumers_use_canonical_adapter(self) -> None:
        agents = (AI_TOOLS_ROOT / "agents.nix").read_text(encoding="utf-8")
        service = (
            AI_TOOLS_ROOT.parents[1]
            / "home"
            / "services"
            / "cliproxyapi"
            / "default.nix"
        ).read_text(encoding="utf-8")

        self.assertIn("modelRouting.modelsForRole", agents)
        self.assertIn("modelRouting.gatewayAgentSpecs", agents)
        self.assertIn("Explicit model route", agents)
        self.assertIn("modelRouting.cliproxyAliases", service)
        self.assertNotIn("claude-gpt-5.6-luna", agents)
        self.assertNotIn("claude-gpt-5.6-luna", service)

    @unittest.skipUnless(shutil.which("nix"), "nix is not installed")
    def test_shared_worker_core_reaches_every_provider_projection(self) -> None:
        for gateway_enabled in (False, True):
            projection = json.loads(
                self._nix_eval(self._provider_projection_expression(gateway_enabled))
            )
            instructions = {
                "claude": projection["claude"],
                "codex": {
                    name: agent["developer_instructions"]
                    for name, agent in projection["codex"].items()
                },
                "copilot": projection["copilot"],
                "opencode": projection["opencode"],
            }

            for provider, agents in instructions.items():
                for name, content in agents.items():
                    with self.subTest(
                        gateway_enabled=gateway_enabled,
                        provider=provider,
                        agent=name,
                    ):
                        normalized = " ".join(content.split())
                        self.assertIn(
                            "one child worker in a parent-owned workflow", normalized
                        )
                        self.assertIn(
                            "Never overwrite another actor's changes", normalized
                        )
                        self.assertIn("skill or tool lane", normalized)
                        self.assertIn("Write like a technical peer", normalized)
                        self.assertIn("Remove canned framing", normalized)

    @unittest.skipUnless(shutil.which("nix"), "nix is not installed")
    def test_fable_gateway_projection_is_read_only(self) -> None:
        projection = json.loads(
            self._nix_eval(self._provider_projection_expression(True))
        )

        self.assertIn(
            'tools: "Read, Bash, Grep, Glob"', projection["claude"]["fable-5-1"]
        )
        self.assertEqual(projection["codex"]["fable-5-1"]["sandbox_mode"], "read-only")
        self.assertIn('"edit": false', projection["opencode"]["fable-5-1"])
        self.assertIn('"write": false', projection["opencode"]["fable-5-1"])

    @unittest.skipUnless(shutil.which("nix"), "nix is not installed")
    def test_provider_projections_match_frozen_baseline(self) -> None:
        expected_digests = {
            False: "6606394454230703bbcbe9da6606d3b71547ce8faed5a10a960fbc2b81934b6e",
            True: "fb13aee156be6c0df60659eab0e8b41a72d8da67a330d03c142a72962fe57f4d",
        }

        for gateway_enabled, expected_digest in expected_digests.items():
            with self.subTest(gateway_enabled=gateway_enabled):
                expression = self._provider_projection_expression(gateway_enabled)
                result = self._nix_eval(expression)

                self.assertEqual(hashlib.sha256(result).hexdigest(), expected_digest)

    @unittest.skipUnless(shutil.which("nix"), "nix is not installed")
    def test_frontmatter_string_scalars_use_safe_deterministic_quotes(self) -> None:
        projection = json.loads(self._nix_eval(self._frontmatter_expression()))

        self.assertIn('name: "worker: # tag"', projection["claude"])
        self.assertIn('description: "description: # tag"', projection["claude"])
        self.assertIn('tools: "Read: # tag"', projection["claude"])
        self.assertIn('model: "claude: # model"', projection["claude"])
        self.assertIn('description: "description: # tag"', projection["opencode"])
        self.assertIn('mode: "mode: # tag"', projection["opencode"])
        self.assertIn('model: "opencode: # model"', projection["opencode"])
        self.assertIn('"bash": false', projection["opencode"])
        self.assertIn('"permission: # key": "allow: # value"', projection["opencode"])
        self.assertIn('name: "worker: # tag"', projection["copilot"])
        self.assertIn('model: "copilot: # model"', projection["copilot"])

    @unittest.skipUnless(shutil.which("nix"), "nix is not installed")
    def test_control_character_injection_is_rejected_across_projections(self) -> None:
        projections = {
            "claude": ("claude", "toClaudeMarkdown.mechanic"),
            "codex": ("codex", "toCodexAgents.mechanic.model"),
            "copilot": ("copilot", "toCopilotMarkdown.mechanic"),
            "opencode": ("opencode", "toOpenCodeMarkdown.mechanic"),
        }

        for label, (model_field, projection) in projections.items():
            with self.subTest(label=label):
                result = self._nix_eval_result(
                    self._injected_projection_expression(model_field, projection)
                )
                self.assertNotEqual(result.returncode, 0)
                self.assertIn("control characters", result.stderr.decode())

    @unittest.skipUnless(shutil.which("nix"), "nix is not installed")
    def test_nix_adapter_rejects_missing_published_alias(self) -> None:
        invalid = copy.deepcopy(self.registry)
        invalid["cliproxy_alias_order"].pop()

        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            registry_path = (
                root
                / "skills"
                / "multi-provider-sdlc"
                / "references"
                / "model-routing.json"
            )
            registry_path.parent.mkdir(parents=True)
            registry_path.write_text(json.dumps(invalid), encoding="utf-8")
            shutil.copy2(
                AI_TOOLS_ROOT / "model-routing.nix", root / "model-routing.nix"
            )
            result = self._nix_eval_result(self._temporary_adapter_expression(root))

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("omits published models", result.stderr.decode())

    @unittest.skipUnless(shutil.which("nix"), "nix is not installed")
    def test_nix_adapter_rejects_policy_control_characters(self) -> None:
        invalid = copy.deepcopy(self.registry)
        invalid["models"]["opus-5"]["description"] = "worker\ndescription"

        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            registry_path = (
                root
                / "skills"
                / "multi-provider-sdlc"
                / "references"
                / "model-routing.json"
            )
            registry_path.parent.mkdir(parents=True)
            registry_path.write_text(json.dumps(invalid), encoding="utf-8")
            shutil.copy2(
                AI_TOOLS_ROOT / "model-routing.nix", root / "model-routing.nix"
            )
            result = self._nix_eval_result(self._temporary_adapter_expression(root))

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("control characters", result.stderr.decode())

    @unittest.skipUnless(shutil.which("nix"), "nix is not installed")
    def test_nix_adapter_matches_registry_and_preserves_overrides(self) -> None:
        projection = json.loads(self._nix_eval(self._adapter_expression()))
        models = self.registry["models"]
        expected_aliases = [
            {
                "provider": models[name]["upstream_provider"],
                "alias": models[name]["gateway_alias"],
                "model": models[name]["upstream_model"],
                "displayName": models[name]["display_name"],
            }
            for name in self.registry["cliproxy_alias_order"]
        ]
        expected_defaults = {
            provider: models[name]["upstream_model"]
            for provider, name in self.registry["gateway_defaults"].items()
        }
        expected_direct = {
            model["gateway_alias"]: {"name": model["display_name"]}
            for model in models.values()
            if not model["publish_alias"]
        }

        self.assertEqual(projection["aliases"], expected_aliases)
        self.assertEqual(projection["defaults"], expected_defaults)
        self.assertEqual(projection["directDefault"], expected_direct)
        self.assertEqual(projection["directFable"], expected_direct)
        self.assertEqual(projection["directSonnet"], expected_direct)
        self.assertEqual(
            projection["directCustom"],
            expected_direct
            | {
                "claude-custom": {
                    "name": models[self.registry["gateway_defaults"]["claude"]][
                        "display_name"
                    ]
                }
            },
        )

    @unittest.skipUnless(shutil.which("nix"), "nix is not installed")
    def test_custom_claude_mapping_keeps_its_display_name(self) -> None:
        projection = json.loads(self._nix_eval(self._custom_mapping_expression()))

        self.assertEqual(projection["claude-custom"], {"name": "Custom Claude"})

    @staticmethod
    def _nix_eval(expression: str) -> bytes:
        result = ModelRoutingTests._nix_eval_result(expression)
        result.check_returncode()
        return result.stdout

    @staticmethod
    def _nix_eval_result(expression: str) -> subprocess.CompletedProcess[bytes]:
        nix = shutil.which("nix")
        assert nix is not None
        return subprocess.run(
            [
                nix,
                "eval",
                "--json",
                "--impure",
                "--expr",
                expression,
            ],
            cwd=REPO_ROOT,
            check=False,
            capture_output=True,
        )

    @staticmethod
    def _provider_projection_expression(gateway_enabled: bool) -> str:
        enabled = "true" if gateway_enabled else "false"
        repo = json.dumps(str(REPO_ROOT))
        return f"""
          let
            repo = builtins.toPath {repo};
            flake = builtins.getFlake (toString repo);
            aiTools = import (repo + "/modules/common/ai-tools") {{
              inherit (flake.inputs.nixpkgs) lib;
              gatewayEnabled = {enabled};
            }};
          in
          {{
            codex = aiTools.codex.agents;
            claude = aiTools.claudeCode.agents;
            copilot = aiTools.githubCopilotCli.agents;
            opencode = aiTools.opencode.renderAgents;
          }}
        """

    @staticmethod
    def _adapter_expression() -> str:
        repo = json.dumps(str(REPO_ROOT))
        return f"""
          let
            repo = builtins.toPath {repo};
            flake = builtins.getFlake (toString repo);
            modelRouting = (import (repo + "/modules/common/ai-tools") {{
              inherit (flake.inputs.nixpkgs) lib;
            }}).modelRouting;
          in
          {{
            defaults = modelRouting.defaultUpstreamModels;
            aliases = modelRouting.cliproxyAliases;
            directDefault = modelRouting.directGatewayModelsFor {{}} "claude-opus-5";
            directFable = modelRouting.directGatewayModelsFor {{}} "claude-fable-5-1";
            directSonnet = modelRouting.directGatewayModelsFor {{}} "claude-sonnet-5";
            directCustom = modelRouting.directGatewayModelsFor {{}} "claude-custom";
          }}
        """

    @staticmethod
    def _frontmatter_expression() -> str:
        repo = json.dumps(str(REPO_ROOT))
        return f"""
          let
            repo = builtins.toPath {repo};
            flake = builtins.getFlake (toString repo);
            renderers = import (repo + "/modules/common/ai-tools/agents.nix") {{
              inherit (flake.inputs.nixpkgs) lib;
            }};
            agent = {{
              name = "worker: # tag";
              description = "description: # tag";
              tools = [ "Read: # tag" ];
              mode = "mode: # tag";
              permission."permission: # key" = "allow: # value";
              model = {{
                claude = "claude: # model";
                copilot = "copilot: # model";
                opencode = "opencode: # model";
              }};
              content = "Worker body.";
            }};
          in
          {{
            claude = renderers.renderClaudeAgent agent;
            copilot = renderers.renderCopilotAgent agent;
            opencode = renderers.renderOpenCodeAgent agent;
          }}
        """

    @staticmethod
    def _injected_projection_expression(model_field: str, projection: str) -> str:
        repo = json.dumps(str(REPO_ROOT))
        invalid = json.dumps("safe-model\nmodel: injected")
        model_values = {
            provider: invalid if provider == model_field else json.dumps("safe-model")
            for provider in ("claude", "codex", "copilot", "opencode")
        }
        return f"""
          let
            repo = builtins.toPath {repo};
            flake = builtins.getFlake (toString repo);
            modelRouting = {{
              modelsForRole = _role: {{
                claude = {model_values["claude"]};
                codex = {model_values["codex"]};
                copilot = {model_values["copilot"]};
                opencode = {model_values["opencode"]};
              }};
              reasoningEffortForRole = _role: {{ codex = "medium"; }};
              gatewayAgentSpecs = {{}};
            }};
            renderers = import (repo + "/modules/common/ai-tools/agents.nix") {{
              inherit (flake.inputs.nixpkgs) lib;
              inherit modelRouting;
            }};
          in
          renderers.{projection}
        """

    @staticmethod
    def _temporary_adapter_expression(root: Path) -> str:
        repo = json.dumps(str(REPO_ROOT))
        adapter = json.dumps(str(root / "model-routing.nix"))
        return f"""
          let
            repo = builtins.toPath {repo};
            flake = builtins.getFlake (toString repo);
            modelRouting = import (builtins.toPath {adapter}) {{
              inherit (flake.inputs.nixpkgs) lib;
            }};
          in
          modelRouting.cliproxyAliases
        """

    @staticmethod
    def _custom_mapping_expression() -> str:
        repo = json.dumps(str(REPO_ROOT))
        return f"""
          let
            repo = builtins.toPath {repo};
            flake = builtins.getFlake (toString repo);
            lib = flake.inputs.nixpkgs.lib;
            home = flake.homeConfigurations."khaneliman@khanelinix".extendModules {{
              modules = [
                {{
                  khanelinix.services.cliproxyapi.models.claude =
                    lib.mkForce "custom-upstream";
                  khanelinix.services.cliproxyapi.claudeCodeModels = lib.mkForce [
                    {{
                      provider = "claude";
                      model = "custom-upstream";
                      alias = "claude-custom";
                      displayName = "Custom Claude";
                    }}
                  ];
                }}
              ];
            }};
          in
          home.config.programs.opencode.settings.provider.cliproxyapi.models
        """


if __name__ == "__main__":
    unittest.main()
