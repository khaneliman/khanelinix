#!/usr/bin/env python3
"""Generate provider marketplace files from catalog.json and canonical skills.

Writes the shared plugin tree (marketplace/plugins/, one Codex and one Claude
manifest per plugin over a single skill copy), the Codex marketplace index,
and the Claude marketplace index. marketplace.py validates the result; it
never writes.
"""

from __future__ import annotations

import json
import shutil
from pathlib import Path
from typing import Any

MARKETPLACE_DIR = Path(__file__).resolve().parent
ROOT = MARKETPLACE_DIR.parents[3]
SKILLS_DIR = MARKETPLACE_DIR.parent / "skills"
PLUGINS_TREE = MARKETPLACE_DIR / "plugins"
CODEX_INDEX = ROOT / ".agents/plugins/marketplace.json"
CLAUDE_INDEX = ROOT / ".claude-plugin/marketplace.json"


def dump(path: Path, payload: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, indent="\t") + "\n", encoding="utf-8")


def main() -> None:
    catalog = json.loads((MARKETPLACE_DIR / "catalog.json").read_text())
    marketplace = catalog["marketplace"]
    owner = marketplace["owner"]
    plugins = catalog["plugins"]

    if PLUGINS_TREE.exists():
        shutil.rmtree(PLUGINS_TREE)
    for plugin in plugins:
        name = plugin["name"]
        plugin_dir = PLUGINS_TREE / name
        dump(
            plugin_dir / ".codex-plugin/plugin.json",
            {
                "name": name,
                "version": plugin["version"],
                "description": plugin["description"],
                "author": owner,
                "skills": "./skills/",
                "interface": {
                    "displayName": plugin["displayName"],
                    "shortDescription": plugin["description"],
                },
            },
        )
        dump(
            plugin_dir / ".claude-plugin/plugin.json",
            {
                "name": name,
                "displayName": plugin["displayName"],
                "description": plugin["description"],
                "version": plugin["version"],
                "author": owner,
            },
        )
        shutil.copytree(
            SKILLS_DIR / name,
            plugin_dir / "skills" / name,
            ignore=shutil.ignore_patterns("__pycache__", "*.pyc"),
        )

    dump(
        CODEX_INDEX,
        {
            "name": marketplace["name"],
            "interface": {"displayName": marketplace["displayName"]},
            "plugins": [
                {
                    "name": plugin["name"],
                    "source": {
                        "source": "local",
                        "path": "./modules/common/ai-tools/marketplace/plugins/"
                        + plugin["name"],
                    },
                    "policy": {
                        "installation": "AVAILABLE",
                        "authentication": "ON_INSTALL",
                    },
                    "category": plugin["category"],
                }
                for plugin in plugins
            ],
        },
    )

    dump(
        CLAUDE_INDEX,
        {
            "$schema": "https://anthropic.com/claude-code/marketplace.schema.json",
            "name": marketplace["name"],
            "description": marketplace["description"],
            "owner": owner,
            "plugins": [
                {
                    "name": plugin["name"],
                    "description": plugin["description"],
                    "version": plugin["version"],
                    "author": owner,
                    "category": plugin["category"].lower().replace(" ", "-"),
                    "source": "./modules/common/ai-tools/marketplace/plugins/"
                    + plugin["name"],
                }
                for plugin in plugins
            ],
        },
    )
    print(f"synced {len(plugins)} plugins")


if __name__ == "__main__":
    main()
