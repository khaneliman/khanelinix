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
        self.catalog_path = (
            self.root / "modules/common/ai-tools/marketplace/catalog.json"
        )

    def tearDown(self) -> None:
        self.temporary_directory.cleanup()

    def write_json(self, path: Path, payload: Any) -> None:
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(json.dumps(payload), encoding="utf-8")

    def write_skill(self, name: str, *, plugin: bool = True) -> Path:
        skill_dir = self.skills_dir / name
        skill_dir.mkdir(parents=True)
        (skill_dir / "SKILL.md").write_text(
            f"---\nname: {name}\ndescription: Use {name} for tests.\n---\n\n# Test\n",
            encoding="utf-8",
        )
        if plugin:
            self.write_json(
                skill_dir / ".codex-plugin/plugin.json",
                {
                    "name": name,
                    "version": "0.1.0",
                    "description": f"Use {name} for tests.",
                    "author": {"name": "Tester"},
                    "skills": "./",
                },
            )
        return skill_dir

    def write_repository(
        self, published: list[str], excluded: dict[str, str] | None = None
    ) -> None:
        marketplace_metadata = {
            "name": "test-marketplace",
            "displayName": "Test Marketplace",
            "description": "Test marketplace.",
            "owner": {"name": "Tester"},
            "repository": "https://example.com/tester/repository",
        }
        plugins = [
            {"name": name, "version": "0.1.0", "category": "Developer Tools"}
            for name in published
        ]
        self.write_json(
            self.catalog_path,
            {
                "schemaVersion": 1,
                "marketplace": marketplace_metadata,
                "plugins": plugins,
                "excluded": excluded or {},
            },
        )
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
                            "path": f"./modules/common/ai-tools/skills/{name}",
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
                        "source": f"./modules/common/ai-tools/skills/{name}",
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
        self.write_skill("beta-skill", plugin=False)
        self.write_repository(["alpha-skill"])

        with self.assertRaisesRegex(
            marketplace.MarketplaceError, "missing: beta-skill"
        ):
            marketplace.validate_repository(self.root)

    def test_excluded_skill_must_not_expose_codex_plugin(self) -> None:
        self.write_skill("alpha-skill")
        self.write_skill("private-skill")
        self.write_repository(
            ["alpha-skill"], {"private-skill": "Not redistributable."}
        )

        with self.assertRaisesRegex(
            marketplace.MarketplaceError, "manifests do not match"
        ):
            marketplace.validate_repository(self.root)

    def test_requires_codex_plugin_manifest(self) -> None:
        self.write_skill("alpha-skill", plugin=False)
        self.write_repository(["alpha-skill"])

        with self.assertRaisesRegex(marketplace.MarketplaceError, "unable to read"):
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

        with self.assertRaisesRegex(marketplace.MarketplaceError, "version mismatch"):
            marketplace.validate_repository(self.root)

    def test_rejects_nested_codex_skills_path(self) -> None:
        self.write_skill("alpha-skill")
        self.write_repository(["alpha-skill"])
        path = self.skills_dir / "alpha-skill/.codex-plugin/plugin.json"
        payload = self.load_json(path)
        payload["skills"] = "./skills/"
        self.write_json(path, payload)

        with self.assertRaisesRegex(marketplace.MarketplaceError, "must equal"):
            marketplace.validate_repository(self.root)


if __name__ == "__main__":
    unittest.main()
