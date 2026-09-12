from __future__ import annotations

import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from typing import Any

MARKETPLACE_DIR = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(MARKETPLACE_DIR))

import marketplace


class MarketplaceTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary_directory = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary_directory.name)
        self.skills_dir = self.root / marketplace.SKILLS_PATH
        self.catalog_path = (
            self.root / "modules/common/ai-tools/marketplace/catalog.json"
        )

    def tearDown(self) -> None:
        self.temporary_directory.cleanup()

    def write_json(self, path: Path, payload: Any) -> None:
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(json.dumps(payload), encoding="utf-8")

    def skill_body(self, name: str, *, user_only: bool = False) -> str:
        metadata = (
            "disable-model-invocation: true\n"
            'metadata:\n  khanelinix-invocation-mode: "user-only"\n'
            if user_only
            else ""
        )
        return (
            f"---\nname: {name}\ndescription: Use {name} for tests.\n"
            f"{metadata}---\n\n# Test\n"
        )

    def write_skill(self, name: str, *, user_only: bool = False) -> Path:
        skill_dir = self.skills_dir / name
        skill_dir.mkdir(parents=True)
        (skill_dir / "SKILL.md").write_text(
            self.skill_body(name, user_only=user_only), encoding="utf-8"
        )
        return skill_dir

    def write_native_manifests(self, name: str) -> None:
        skill_dir = self.skills_dir / name
        self.write_json(
            skill_dir / ".claude-plugin/plugin.json",
            {
                "name": name,
                "displayName": f"{name} Display",
                "description": f"Use {name} for tests.",
                "version": "0.1.0",
                "author": {"name": "Tester"},
                "skills": "./",
            },
        )
        self.write_json(
            skill_dir / ".codex-plugin/plugin.json",
            {
                "name": name,
                "version": "0.1.0",
                "description": f"Use {name} for tests.",
                "author": {"name": "Tester"},
                "skills": "./.",
                "interface": {
                    "displayName": f"{name} Display",
                    "shortDescription": f"Use {name} for tests.",
                },
            },
        )

    def write_readme(self, bundles: dict[str, Any]) -> None:
        blocks = [
            f"### {name}\n\n```sh\nnpx skills add tester/repository \\\n"
            f"  --skill {' '.join(bundle['plugins'])} --global --copy --yes\n```\n"
            for name, bundle in bundles.items()
        ]
        readme_path = self.catalog_path.parent / "README.md"
        readme_path.parent.mkdir(parents=True, exist_ok=True)
        readme_path.write_text(
            "# Marketplace\n\n" + "\n".join(blocks), encoding="utf-8"
        )

    def write_invocation_readme(self, names: list[str]) -> None:
        readme_path = self.catalog_path.parent / "README.md"
        readme_path.parent.mkdir(parents=True, exist_ok=True)
        rows = "\n".join(f"| `{name}` | Test | `Use ${name}` |" for name in names)
        readme_path.write_text(
            "# Marketplace\n\n"
            "### Explicit-only skills\n\n"
            "| Skill | Purpose | Invocation syntax |\n"
            "| --- | --- | --- |\n"
            f"{rows}\n",
            encoding="utf-8",
        )

    def write_repository(
        self,
        published: list[str],
        excluded: dict[str, str] | None = None,
        bundles: dict[str, Any] | None = None,
        dependencies: dict[str, dict[str, list[str]]] | None = None,
    ) -> None:
        for name in published:
            self.write_native_manifests(name)
        marketplace_metadata = {
            "name": "test-marketplace",
            "displayName": "Test Marketplace",
            "description": "Test marketplace.",
            "owner": {"name": "Tester"},
            "repository": "https://example.com/tester/repository",
        }
        plugins = [
            {
                "name": name,
                "dependencies": (dependencies or {}).get(
                    name, {"required": [], "optional": []}
                ),
                "displayName": f"{name} Display",
                "description": f"Use {name} for tests.",
                "version": "0.1.0",
                "category": "Developer Tools",
            }
            for name in published
        ]
        catalog: dict[str, Any] = {
            "schemaVersion": 1,
            "marketplace": marketplace_metadata,
            "plugins": plugins,
            "excluded": excluded or {},
        }
        if bundles is not None:
            catalog["bundles"] = bundles
            self.write_readme(bundles)
        self.write_json(self.catalog_path, catalog)
        self.write_json(
            self.root / marketplace.CODEX_MARKETPLACE_PATH,
            {
                "name": "test-marketplace",
                "interface": {"displayName": "Test Marketplace"},
                "plugins": [
                    {
                        "name": name,
                        "source": {
                            "source": "local",
                            "path": ("./modules/common/ai-tools/skills/" + name),
                        },
                        "policy": {
                            "installation": "AVAILABLE",
                            "authentication": "ON_INSTALL",
                        },
                        "category": "Developer Tools",
                    }
                    for name in published
                ],
            },
        )
        self.write_json(
            self.root / marketplace.CLAUDE_MARKETPLACE_PATH,
            {
                "$schema": "https://anthropic.com/claude-code/marketplace.schema.json",
                "name": "test-marketplace",
                "description": "Test marketplace.",
                "owner": {"name": "Tester"},
                "plugins": [
                    {
                        "name": name,
                        "description": f"Use {name} for tests.",
                        "version": "0.1.0",
                        "author": {"name": "Tester"},
                        "category": "developer-tools",
                        "source": ("./modules/common/ai-tools/skills/" + name),
                    }
                    for name in published
                ],
            },
        )

    def load_json(self, path: Path) -> dict[str, Any]:
        return json.loads(path.read_text(encoding="utf-8"))

    def test_validates_checked_in_marketplaces(self) -> None:
        self.write_skill("alpha-skill")
        self.write_repository(["alpha-skill"])

        result = marketplace.validate_repository(self.root)

        self.assertEqual(result["plugins"], 1)
        self.assertEqual(result["marketplace"], "test-marketplace")

    def test_catalog_requires_decision_for_every_skill(self) -> None:
        self.write_skill("alpha-skill")
        self.write_skill("beta-skill")
        self.write_repository(["alpha-skill"])

        with self.assertRaisesRegex(
            marketplace.MarketplaceError, "missing: beta-skill"
        ):
            marketplace.validate_repository(self.root)

    def test_excluded_skill_must_not_have_provider_manifests(self) -> None:
        self.write_skill("alpha-skill")
        self.write_skill("private-skill")
        self.write_repository(
            ["alpha-skill"], {"private-skill": "Not redistributable."}
        )
        self.write_native_manifests("private-skill")

        with self.assertRaisesRegex(
            marketplace.MarketplaceError, "excluded skill must not contain"
        ):
            marketplace.validate_repository(self.root)

    def test_requires_codex_plugin_manifest(self) -> None:
        self.write_skill("alpha-skill")
        self.write_repository(["alpha-skill"])
        manifest = self.skills_dir / "alpha-skill/.codex-plugin/plugin.json"
        manifest.unlink()

        with self.assertRaisesRegex(marketplace.MarketplaceError, "unable to read"):
            marketplace.validate_repository(self.root)

    def test_requires_claude_plugin_manifest(self) -> None:
        self.write_skill("alpha-skill")
        self.write_repository(["alpha-skill"])
        manifest = self.skills_dir / "alpha-skill/.claude-plugin/plugin.json"
        manifest.unlink()

        with self.assertRaisesRegex(marketplace.MarketplaceError, "unable to read"):
            marketplace.validate_repository(self.root)

    def test_rejects_legacy_plugin_tree(self) -> None:
        self.write_skill("alpha-skill")
        self.write_repository(["alpha-skill"])
        legacy = self.root / marketplace.PLUGINS_TREE_PATH / "alpha-skill"
        legacy.mkdir(parents=True)

        with self.assertRaisesRegex(marketplace.MarketplaceError, "legacy marketplace"):
            marketplace.validate_repository(self.root)

    def test_user_only_skill_requires_native_control(self) -> None:
        self.write_skill("manual-skill", user_only=True)
        self.write_repository(["manual-skill"])
        self.write_invocation_readme(["manual-skill"])

        result = marketplace.validate_repository(self.root)

        self.assertEqual(result["plugins"], 1)
        manifest = self.skills_dir / "manual-skill/SKILL.md"
        rendered = manifest.read_text(encoding="utf-8")
        self.assertIn("disable-model-invocation: true", rendered)

        manifest.write_text(
            rendered.replace("disable-model-invocation: true\n", "")
            + "\nExample: disable-model-invocation: true\n",
            encoding="utf-8",
        )
        with self.assertRaisesRegex(
            marketplace.MarketplaceError, "must declare disable-model-invocation"
        ):
            marketplace.validate_repository(self.root)

    def test_user_only_documentation_must_match_metadata(self) -> None:
        self.write_skill("manual-skill", user_only=True)
        self.write_repository(["manual-skill"])
        self.write_invocation_readme(["stale-skill"])

        with self.assertRaisesRegex(
            marketplace.MarketplaceError, "explicit-only skill table is out of sync"
        ):
            marketplace.validate_repository(self.root)

    def test_rejects_non_native_codex_skills_path(self) -> None:
        self.write_skill("alpha-skill")
        self.write_repository(["alpha-skill"])
        path = self.skills_dir / "alpha-skill/.codex-plugin/plugin.json"
        payload = self.load_json(path)
        payload["skills"] = "./"
        self.write_json(path, payload)

        with self.assertRaisesRegex(
            marketplace.MarketplaceError, "Codex plugin manifest mismatch"
        ):
            marketplace.validate_repository(self.root)

    def test_rejects_missing_interface(self) -> None:
        self.write_skill("alpha-skill")
        self.write_repository(["alpha-skill"])
        path = self.skills_dir / "alpha-skill/.codex-plugin/plugin.json"
        payload = self.load_json(path)
        del payload["interface"]
        self.write_json(path, payload)

        with self.assertRaisesRegex(marketplace.MarketplaceError, "manifest mismatch"):
            marketplace.validate_repository(self.root)

    def test_rejects_codex_source_mismatch(self) -> None:
        self.write_skill("alpha-skill")
        self.write_repository(["alpha-skill"])
        path = self.root / marketplace.CODEX_MARKETPLACE_PATH
        payload = self.load_json(path)
        payload["plugins"][0]["source"]["path"] = "./plugins/alpha-skill"
        self.write_json(path, payload)

        with self.assertRaisesRegex(marketplace.MarketplaceError, "source mismatch"):
            marketplace.validate_repository(self.root)

    def test_rejects_nonstandard_codex_entry_keys(self) -> None:
        self.write_skill("alpha-skill")
        self.write_repository(["alpha-skill"])
        path = self.root / marketplace.CODEX_MARKETPLACE_PATH
        payload = self.load_json(path)
        payload["plugins"][0]["description"] = "Nonstandard."
        self.write_json(path, payload)

        with self.assertRaisesRegex(marketplace.MarketplaceError, "nonstandard keys"):
            marketplace.validate_repository(self.root)

    def test_rejects_claude_source_mismatch(self) -> None:
        self.write_skill("alpha-skill")
        self.write_repository(["alpha-skill"])
        path = self.root / marketplace.CLAUDE_MARKETPLACE_PATH
        payload = self.load_json(path)
        payload["plugins"][0]["source"] = "./plugins/alpha-skill"
        self.write_json(path, payload)

        with self.assertRaisesRegex(marketplace.MarketplaceError, "source mismatch"):
            marketplace.validate_repository(self.root)

    def test_rejects_marketplace_order_mismatch(self) -> None:
        self.write_skill("alpha-skill")
        self.write_skill("beta-skill")
        self.write_repository(["alpha-skill", "beta-skill"])
        path = self.root / marketplace.CLAUDE_MARKETPLACE_PATH
        payload = self.load_json(path)
        payload["plugins"].reverse()
        self.write_json(path, payload)

        with self.assertRaisesRegex(marketplace.MarketplaceError, "order"):
            marketplace.validate_repository(self.root)

    def test_rejects_plugin_version_mismatch(self) -> None:
        self.write_skill("alpha-skill")
        self.write_repository(["alpha-skill"])
        path = self.skills_dir / "alpha-skill/.codex-plugin/plugin.json"
        payload = self.load_json(path)
        payload["version"] = "0.2.0"
        self.write_json(path, payload)

        with self.assertRaisesRegex(marketplace.MarketplaceError, "manifest mismatch"):
            marketplace.validate_repository(self.root)

    def test_documented_bundle_passes(self) -> None:
        self.write_skill("alpha-skill")
        self.write_skill("beta-skill")
        bundles = {
            "core": {
                "description": "Core set.",
                "plugins": ["alpha-skill", "beta-skill"],
            }
        }
        self.write_repository(["alpha-skill", "beta-skill"], bundles=bundles)

        result = marketplace.validate_repository(self.root)

        self.assertEqual(result["bundles"], {"core": ["alpha-skill", "beta-skill"]})

    def test_bundle_member_must_be_published(self) -> None:
        self.write_skill("alpha-skill")
        self.write_skill("private-skill")
        bundles = {
            "core": {
                "description": "Core set.",
                "plugins": ["alpha-skill", "private-skill"],
            }
        }
        self.write_repository(
            ["alpha-skill"],
            {"private-skill": "Not redistributable."},
            bundles=bundles,
        )

        with self.assertRaisesRegex(
            marketplace.MarketplaceError, "unpublished skill: private-skill"
        ):
            marketplace.validate_repository(self.root)

    def test_bundle_name_must_not_collide_with_skill(self) -> None:
        self.write_skill("alpha-skill")
        bundles = {
            "alpha-skill": {"description": "Collides.", "plugins": ["alpha-skill"]}
        }
        self.write_repository(["alpha-skill"], bundles=bundles)

        with self.assertRaisesRegex(marketplace.MarketplaceError, "collides"):
            marketplace.validate_repository(self.root)

    def test_bundle_readme_command_must_stay_in_sync(self) -> None:
        self.write_skill("alpha-skill")
        self.write_skill("beta-skill")
        bundles = {
            "core": {
                "description": "Core set.",
                "plugins": ["alpha-skill", "beta-skill"],
            }
        }
        self.write_repository(["alpha-skill", "beta-skill"], bundles=bundles)
        self.write_readme(
            {"core": {"description": "Core set.", "plugins": ["alpha-skill"]}}
        )

        with self.assertRaisesRegex(
            marketplace.MarketplaceError, "command out of sync: core"
        ):
            marketplace.validate_repository(self.root)

    def test_selected_reports_incomplete_dependency(self) -> None:
        self.write_skill("workflow")
        self.write_skill("principles")
        self.write_repository(
            ["workflow", "principles"],
            dependencies={"workflow": {"required": ["principles"], "optional": []}},
        )

        with self.assertRaisesRegex(
            marketplace.MarketplaceError, "missing: principles"
        ):
            marketplace.validate_selected(
                ["workflow"], marketplace.load_catalog(self.catalog_path)
            )

    def test_selected_reports_transitive_missing_dependency(self) -> None:
        for name in ("alpha-skill", "beta-skill", "gamma-skill"):
            self.write_skill(name)
        self.write_repository(
            ["alpha-skill", "beta-skill", "gamma-skill"],
            dependencies={
                "alpha-skill": {"required": ["beta-skill"], "optional": []},
                "beta-skill": {"required": ["gamma-skill"], "optional": []},
            },
        )

        with self.assertRaisesRegex(
            marketplace.MarketplaceError, "missing: gamma-skill"
        ):
            marketplace.validate_selected(
                ["alpha-skill"],
                marketplace.load_catalog(self.catalog_path),
                {"alpha-skill", "beta-skill"},
            )

    def test_selected_accepts_complete_selection(self) -> None:
        self.write_skill("alpha-skill")
        self.write_skill("beta-skill")
        self.write_repository(
            ["alpha-skill", "beta-skill"],
            dependencies={"alpha-skill": {"required": ["beta-skill"], "optional": []}},
        )

        result = marketplace.validate_selected(
            ["alpha-skill"],
            marketplace.load_catalog(self.catalog_path),
            {"alpha-skill", "beta-skill"},
        )

        self.assertEqual(result["required"], ["alpha-skill", "beta-skill"])

    def test_unknown_optional_dependency_is_rejected(self) -> None:
        self.write_skill("alpha-skill")
        self.write_repository(
            ["alpha-skill"],
            dependencies={
                "alpha-skill": {"required": [], "optional": ["missing-skill"]}
            },
        )

        with self.assertRaisesRegex(
            marketplace.MarketplaceError, "unknown optional dependency"
        ):
            marketplace.load_catalog(self.catalog_path)

    def test_installed_inventory_ignores_nested_archive(self) -> None:
        installed_root = self.root / "installed"
        installed_root.mkdir()
        (installed_root / "alpha-skill").mkdir()
        (installed_root / "alpha-skill/SKILL.md").write_text("---\n---\n")
        archive = installed_root / "archive/old-skill"
        archive.mkdir(parents=True)
        (archive / "SKILL.md").write_text("---\n---\n")

        self.assertEqual(
            marketplace.discover_installed_skills(installed_root), {"alpha-skill"}
        )

    def test_mutual_required_dependencies_are_cycle_safe(self) -> None:
        for name in ("alpha-skill", "beta-skill"):
            self.write_skill(name)
        self.write_repository(
            ["alpha-skill", "beta-skill"],
            dependencies={
                "alpha-skill": {"required": ["beta-skill"], "optional": []},
                "beta-skill": {"required": ["alpha-skill"], "optional": []},
            },
        )

        result = marketplace.validate_selected(
            ["alpha-skill"],
            marketplace.load_catalog(self.catalog_path),
            {"alpha-skill", "beta-skill"},
        )

        self.assertEqual(result["required"], ["alpha-skill", "beta-skill"])

    def test_workflow_requires_declared_review_route(self) -> None:
        catalog = marketplace.load_catalog(MARKETPLACE_DIR / "catalog.json")
        installed = set(marketplace.catalog_plugin_names(catalog)) - {"interrogate"}
        with self.assertRaisesRegex(
            marketplace.MarketplaceError, "missing: interrogate"
        ):
            marketplace.validate_selected(["engineering-workflow"], catalog, installed)

    def test_github_selection_reports_missing_workflow_routes(self) -> None:
        catalog = marketplace.load_catalog(MARKETPLACE_DIR / "catalog.json")
        for missing in ("engineering-workflow", "figure-it-out", "git-toolkit"):
            with self.subTest(missing=missing):
                installed = set(marketplace.catalog_plugin_names(catalog)) - {missing}
                with self.assertRaisesRegex(
                    marketplace.MarketplaceError, "missing: " + missing
                ):
                    marketplace.validate_selected(
                        ["github-toolkit"], catalog, installed
                    )

    def test_malformed_dependency_elements_are_reported(self) -> None:
        self.write_skill("alpha-skill")
        self.write_repository(["alpha-skill"])
        catalog = self.load_json(self.catalog_path)
        catalog["plugins"][0]["dependencies"]["required"] = [{}]
        self.write_json(self.catalog_path, catalog)

        with self.assertRaisesRegex(
            marketplace.MarketplaceError, "has an invalid skill name"
        ):
            marketplace.load_catalog(self.catalog_path)

    def test_real_engineering_workflow_selection_is_complete(self) -> None:
        catalog = marketplace.load_catalog(MARKETPLACE_DIR / "catalog.json")
        result = marketplace.validate_selected(
            ["engineering-workflow"],
            catalog,
            set(marketplace.catalog_plugin_names(catalog)),
        )
        self.assertIn("engineering-principles", result["required"])

    def test_root_only_cli_audits_recognized_inventory(self) -> None:
        self.write_skill("alpha-skill")
        self.write_repository(["alpha-skill"])
        installed_root = self.root / "installed"
        installed_root.mkdir()
        (installed_root / "alpha-skill").mkdir()
        (installed_root / "alpha-skill/SKILL.md").write_text("---\n---\n")
        (installed_root / "third-party").mkdir()
        (installed_root / "third-party/SKILL.md").write_text("---\n---\n")

        result = subprocess.run(
            [
                sys.executable,
                str(MARKETPLACE_DIR / "marketplace.py"),
                "--root",
                str(self.root),
                "--catalog",
                str(self.catalog_path),
                "--installed-root",
                str(installed_root),
            ],
            check=True,
            capture_output=True,
            text=True,
        )

        self.assertEqual(json.loads(result.stdout)["selected"], ["alpha-skill"])


if __name__ == "__main__":
    unittest.main()
