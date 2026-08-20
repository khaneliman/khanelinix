from __future__ import annotations

import json
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
        self.plugins_tree = self.root / marketplace.PLUGINS_TREE_PATH
        self.catalog_path = (
            self.root / "modules/common/ai-tools/marketplace/catalog.json"
        )

    def tearDown(self) -> None:
        self.temporary_directory.cleanup()

    def write_json(self, path: Path, payload: Any) -> None:
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(json.dumps(payload), encoding="utf-8")

    def skill_body(self, name: str) -> str:
        return f"---\nname: {name}\ndescription: Use {name} for tests.\n---\n\n# Test\n"

    def write_skill(self, name: str) -> Path:
        skill_dir = self.skills_dir / name
        skill_dir.mkdir(parents=True)
        (skill_dir / "SKILL.md").write_text(self.skill_body(name), encoding="utf-8")
        return skill_dir

    def write_plugin(self, name: str) -> Path:
        plugin_dir = self.plugins_tree / name
        self.write_json(
            plugin_dir / ".claude-plugin/plugin.json",
            {
                "name": name,
                "displayName": f"{name} Display",
                "description": f"Use {name} for tests.",
                "version": "0.1.0",
                "author": {"name": "Tester"},
            },
        )
        self.write_json(
            plugin_dir / ".codex-plugin/plugin.json",
            {
                "name": name,
                "version": "0.1.0",
                "description": f"Use {name} for tests.",
                "author": {"name": "Tester"},
                "skills": "./skills/",
                "interface": {
                    "displayName": f"{name} Display",
                    "shortDescription": f"Use {name} for tests.",
                },
            },
        )
        payload = plugin_dir / "skills" / name / "SKILL.md"
        payload.parent.mkdir(parents=True, exist_ok=True)
        payload.write_text(self.skill_body(name), encoding="utf-8")
        return plugin_dir

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

    def write_repository(
        self,
        published: list[str],
        excluded: dict[str, str] | None = None,
        bundles: dict[str, Any] | None = None,
    ) -> None:
        for name in published:
            self.write_plugin(name)
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
                            "path": (
                                "./modules/common/ai-tools/marketplace/plugins/" + name
                            ),
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
                        "source": (
                            "./modules/common/ai-tools/marketplace/plugins/" + name
                        ),
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

    def test_excluded_skill_must_not_have_codex_plugin(self) -> None:
        self.write_skill("alpha-skill")
        self.write_skill("private-skill")
        self.write_repository(
            ["alpha-skill"], {"private-skill": "Not redistributable."}
        )
        self.write_plugin("private-skill")

        with self.assertRaisesRegex(
            marketplace.MarketplaceError, "tree does not match"
        ):
            marketplace.validate_repository(self.root)

    def test_requires_codex_plugin_manifest(self) -> None:
        self.write_skill("alpha-skill")
        self.write_repository(["alpha-skill"])
        manifest = self.plugins_tree / "alpha-skill/.codex-plugin/plugin.json"
        manifest.unlink()

        with self.assertRaisesRegex(marketplace.MarketplaceError, "unable to read"):
            marketplace.validate_repository(self.root)

    def test_canonical_skill_must_not_hold_codex_manifest(self) -> None:
        skill_dir = self.write_skill("alpha-skill")
        self.write_repository(["alpha-skill"])
        stray = skill_dir / ".codex-plugin"
        stray.mkdir()
        (stray / "plugin.json").write_text("{}", encoding="utf-8")

        with self.assertRaisesRegex(
            marketplace.MarketplaceError, "must not contain plugin manifests"
        ):
            marketplace.validate_repository(self.root)

    def test_rejects_stale_codex_payload(self) -> None:
        self.write_skill("alpha-skill")
        self.write_repository(["alpha-skill"])
        payload = self.plugins_tree / "alpha-skill/skills/alpha-skill/SKILL.md"
        payload.write_text(payload.read_text() + "\nDrift.\n", encoding="utf-8")

        with self.assertRaisesRegex(marketplace.MarketplaceError, "out of sync"):
            marketplace.validate_repository(self.root)

    def test_ignores_transient_python_bytecode(self) -> None:
        skill_dir = self.write_skill("alpha-skill")
        self.write_repository(["alpha-skill"])
        payload_dir = self.plugins_tree / "alpha-skill/skills/alpha-skill"
        relative_cache = Path("tests/__pycache__/test_contract.cpython-314.pyc")
        canonical_cache = skill_dir / relative_cache
        plugin_cache = payload_dir / relative_cache
        canonical_cache.parent.mkdir(parents=True)
        plugin_cache.parent.mkdir(parents=True)
        canonical_cache.write_bytes(b"canonical transient bytecode")
        plugin_cache.write_bytes(b"plugin transient bytecode")

        result = marketplace.validate_repository(self.root)

        self.assertEqual(result["plugins"], 1)

    def test_rejects_root_skills_path(self) -> None:
        self.write_skill("alpha-skill")
        self.write_repository(["alpha-skill"])
        path = self.plugins_tree / "alpha-skill/.codex-plugin/plugin.json"
        payload = self.load_json(path)
        payload["skills"] = "./"
        self.write_json(path, payload)

        with self.assertRaisesRegex(
            marketplace.MarketplaceError, "must equal ./skills/"
        ):
            marketplace.validate_repository(self.root)

    def test_rejects_missing_interface(self) -> None:
        self.write_skill("alpha-skill")
        self.write_repository(["alpha-skill"])
        path = self.plugins_tree / "alpha-skill/.codex-plugin/plugin.json"
        payload = self.load_json(path)
        del payload["interface"]
        self.write_json(path, payload)

        with self.assertRaisesRegex(marketplace.MarketplaceError, "interface mismatch"):
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
        path = self.plugins_tree / "alpha-skill/.codex-plugin/plugin.json"
        payload = self.load_json(path)
        payload["version"] = "0.2.0"
        self.write_json(path, payload)

        with self.assertRaisesRegex(marketplace.MarketplaceError, "version mismatch"):
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


if __name__ == "__main__":
    unittest.main()
