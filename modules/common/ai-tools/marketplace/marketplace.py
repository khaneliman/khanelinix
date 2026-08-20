"""Validate checked-in Codex and Claude skill marketplaces."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any

NAME_RE = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")
SEMVER_RE = re.compile(
    r"^(0|[1-9]\d*)\."
    r"(0|[1-9]\d*)\."
    r"(0|[1-9]\d*)"
    r"(?:-[0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*)?"
    r"(?:\+[0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*)?$"
)
SKILLS_PATH = Path("modules/common/ai-tools/skills")
PLUGINS_TREE_PATH = Path("modules/common/ai-tools/marketplace/plugins")
CODEX_MARKETPLACE_PATH = Path(".agents/plugins/marketplace.json")
CLAUDE_MARKETPLACE_PATH = Path(".claude-plugin/marketplace.json")


class MarketplaceError(ValueError):
    """Report a deterministic marketplace validation failure."""


def load_json_object(path: Path) -> dict[str, Any]:
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except OSError as error:
        raise MarketplaceError(f"unable to read JSON file: {path}") from error
    except json.JSONDecodeError as error:
        raise MarketplaceError(f"invalid JSON file: {path}: {error}") from error
    if not isinstance(payload, dict):
        raise MarketplaceError(f"JSON root must be an object: {path}")
    return payload


def require_string(payload: dict[str, Any], key: str, owner: str) -> str:
    value = payload.get(key)
    if not isinstance(value, str) or not value.strip():
        raise MarketplaceError(f"{owner}.{key} must be a non-empty string")
    return value.strip()


def load_catalog(path: Path) -> dict[str, Any]:
    catalog = load_json_object(path)
    if catalog.get("schemaVersion") != 1:
        raise MarketplaceError("catalog.schemaVersion must equal 1")

    marketplace = catalog.get("marketplace")
    if not isinstance(marketplace, dict):
        raise MarketplaceError("catalog.marketplace must be an object")
    marketplace_name = require_string(marketplace, "name", "catalog.marketplace")
    if NAME_RE.fullmatch(marketplace_name) is None:
        raise MarketplaceError(
            "catalog.marketplace.name must use lower-case kebab-case"
        )
    require_string(marketplace, "displayName", "catalog.marketplace")
    require_string(marketplace, "description", "catalog.marketplace")
    repository = require_string(marketplace, "repository", "catalog.marketplace")
    if not repository.startswith("https://"):
        raise MarketplaceError("catalog.marketplace.repository must use https://")
    owner = marketplace.get("owner")
    if not isinstance(owner, dict):
        raise MarketplaceError("catalog.marketplace.owner must be an object")
    require_string(owner, "name", "catalog.marketplace.owner")

    plugins = catalog.get("plugins")
    if not isinstance(plugins, list) or not plugins:
        raise MarketplaceError("catalog.plugins must be a non-empty array")
    seen: set[str] = set()
    for index, plugin in enumerate(plugins):
        if not isinstance(plugin, dict):
            raise MarketplaceError(f"catalog.plugins[{index}] must be an object")
        owner_label = f"catalog.plugins[{index}]"
        name = require_string(plugin, "name", owner_label)
        if NAME_RE.fullmatch(name) is None:
            raise MarketplaceError(f"invalid plugin name: {name}")
        if name in seen:
            raise MarketplaceError(f"duplicate plugin name: {name}")
        seen.add(name)
        version = require_string(plugin, "version", owner_label)
        if SEMVER_RE.fullmatch(version) is None:
            raise MarketplaceError(f"invalid plugin version for {name}: {version}")
        require_string(plugin, "displayName", owner_label)
        require_string(plugin, "description", owner_label)
        require_string(plugin, "category", owner_label)

    excluded = catalog.get("excluded")
    if not isinstance(excluded, dict):
        raise MarketplaceError("catalog.excluded must be an object")
    for name, reason in excluded.items():
        if not isinstance(name, str) or NAME_RE.fullmatch(name) is None:
            raise MarketplaceError(f"invalid excluded skill name: {name}")
        if name in seen:
            raise MarketplaceError(f"skill cannot be published and excluded: {name}")
        if not isinstance(reason, str) or not reason.strip():
            raise MarketplaceError(f"excluded skill requires a reason: {name}")

    bundles = catalog.get("bundles", {})
    if not isinstance(bundles, dict):
        raise MarketplaceError("catalog.bundles must be an object")
    for bundle_name, bundle in bundles.items():
        if not isinstance(bundle_name, str) or NAME_RE.fullmatch(bundle_name) is None:
            raise MarketplaceError(f"invalid bundle name: {bundle_name}")
        if bundle_name in seen or bundle_name in excluded:
            raise MarketplaceError(
                f"bundle name collides with a skill name: {bundle_name}"
            )
        if not isinstance(bundle, dict):
            raise MarketplaceError(f"catalog.bundles.{bundle_name} must be an object")
        require_string(bundle, "description", f"catalog.bundles.{bundle_name}")
        members = bundle.get("plugins")
        if not isinstance(members, list) or not members:
            raise MarketplaceError(
                f"catalog.bundles.{bundle_name}.plugins must be a non-empty array"
            )
        if members != sorted(set(members)):
            raise MarketplaceError(
                f"bundle members must be unique and sorted: {bundle_name}"
            )
        for member in members:
            if member not in seen:
                raise MarketplaceError(
                    f"bundle {bundle_name} references unpublished skill: {member}"
                )

    return catalog


def decode_frontmatter_value(raw_value: str) -> str:
    value = raw_value.strip()
    if value.startswith('"'):
        try:
            decoded = json.loads(value)
        except json.JSONDecodeError as error:
            raise MarketplaceError(
                f"invalid quoted frontmatter value: {value}"
            ) from error
        if not isinstance(decoded, str):
            raise MarketplaceError("frontmatter value must decode to a string")
        return decoded
    if value.startswith("'") and value.endswith("'"):
        return value[1:-1].replace("''", "'")
    return value


def read_skill_frontmatter(skill_dir: Path) -> dict[str, str]:
    manifest_path = skill_dir / "SKILL.md"
    try:
        lines = manifest_path.read_text(encoding="utf-8").splitlines()
    except OSError as error:
        raise MarketplaceError(
            f"unable to read skill manifest: {manifest_path}"
        ) from error
    if not lines or lines[0] != "---":
        raise MarketplaceError(
            f"skill manifest must start with YAML frontmatter: {manifest_path}"
        )
    try:
        end = lines.index("---", 1)
    except ValueError as error:
        raise MarketplaceError(
            f"skill frontmatter is not closed: {manifest_path}"
        ) from error

    frontmatter: dict[str, str] = {}
    for line in lines[1:end]:
        if not line or line[0].isspace() or ":" not in line:
            continue
        key, raw_value = line.split(":", 1)
        if key in {"name", "description"}:
            frontmatter[key] = decode_frontmatter_value(raw_value)

    name = frontmatter.get("name")
    description = frontmatter.get("description")
    if not name or not description:
        raise MarketplaceError(f"skill requires name and description: {manifest_path}")
    if name != skill_dir.name:
        raise MarketplaceError(
            f"skill name must match directory: {skill_dir.name} != {name}"
        )
    return frontmatter


def discover_skills(skills_dir: Path) -> dict[str, Path]:
    if not skills_dir.is_dir():
        raise MarketplaceError(f"skills directory does not exist: {skills_dir}")
    discovered: dict[str, Path] = {}
    for child in sorted(skills_dir.iterdir()):
        if child.is_dir() and (child / "SKILL.md").is_file():
            read_skill_frontmatter(child)
            discovered[child.name] = child
    if not discovered:
        raise MarketplaceError(f"no skills found: {skills_dir}")
    return discovered


def catalog_plugin_names(catalog: dict[str, Any]) -> list[str]:
    return [plugin["name"] for plugin in catalog["plugins"]]


def validate_catalog_coverage(
    catalog: dict[str, Any], discovered: dict[str, Path]
) -> None:
    published = set(catalog_plugin_names(catalog))
    excluded = set(catalog["excluded"])
    actual = set(discovered)
    missing = sorted(actual - published - excluded)
    unknown = sorted((published | excluded) - actual)
    if missing:
        raise MarketplaceError(
            "catalog must publish or exclude every skill; missing: "
            + ", ".join(missing)
        )
    if unknown:
        raise MarketplaceError(
            "catalog references unknown skills: " + ", ".join(unknown)
        )


def normalized_category(category: str) -> str:
    return category.lower().replace(" ", "-")


def require_plugin_entries(payload: dict[str, Any], provider: str) -> list[Any]:
    entries = payload.get("plugins")
    if not isinstance(entries, list):
        raise MarketplaceError(f"{provider} marketplace plugins must be an array")
    return entries


def require_entry(entry: Any, provider: str, index: int) -> dict[str, Any]:
    if not isinstance(entry, dict):
        raise MarketplaceError(
            f"{provider} marketplace plugin {index} must be an object"
        )
    return entry


def validate_codex_entry(
    entry: dict[str, Any], plugin: dict[str, Any], expected_path: str
) -> None:
    name = plugin["name"]
    if set(entry) != {"name", "source", "policy", "category"}:
        raise MarketplaceError(f"Codex marketplace entry has nonstandard keys: {name}")
    if entry.get("source") != {"source": "local", "path": expected_path}:
        raise MarketplaceError(f"Codex marketplace source mismatch: {name}")
    if entry.get("policy") != {
        "installation": "AVAILABLE",
        "authentication": "ON_INSTALL",
    }:
        raise MarketplaceError(f"Codex marketplace policy mismatch: {name}")
    if entry.get("category") != plugin["category"]:
        raise MarketplaceError(f"Codex marketplace category mismatch: {name}")


def validate_claude_entry(
    entry: dict[str, Any], plugin: dict[str, Any], expected_path: str, owner: Any
) -> None:
    name = plugin["name"]
    if entry.get("source") != expected_path:
        raise MarketplaceError(f"Claude marketplace source mismatch: {name}")
    if entry.get("version") != plugin["version"]:
        raise MarketplaceError(f"Claude marketplace version mismatch: {name}")
    if entry.get("category") != normalized_category(plugin["category"]):
        raise MarketplaceError(f"Claude marketplace category mismatch: {name}")
    if entry.get("author") != owner:
        raise MarketplaceError(f"Claude marketplace author mismatch: {name}")
    if entry.get("description") != plugin["description"]:
        raise MarketplaceError(f"Claude marketplace description mismatch: {name}")


def directory_files(root: Path) -> dict[str, bytes]:
    return {
        path.relative_to(root).as_posix(): path.read_bytes()
        for path in sorted(root.rglob("*"))
        if path.is_file() and "__pycache__" not in path.parts and path.suffix != ".pyc"
    }


def validate_claude_plugin(
    plugin_dir: Path, plugin: dict[str, Any], owner: Any
) -> None:
    name = plugin["name"]
    manifest = load_json_object(plugin_dir / ".claude-plugin" / "plugin.json")
    expected = {
        "name": name,
        "displayName": plugin["displayName"],
        "description": plugin["description"],
        "version": plugin["version"],
        "author": owner,
    }
    if manifest != expected:
        raise MarketplaceError(f"Claude plugin manifest mismatch: {name}")


def validate_codex_plugin(
    plugin_dir: Path, skill_dir: Path, plugin: dict[str, Any], owner: Any
) -> None:
    name = plugin["name"]
    manifest = load_json_object(plugin_dir / ".codex-plugin" / "plugin.json")
    if manifest.get("name") != name:
        raise MarketplaceError(f"Codex plugin name mismatch: {name}")
    if manifest.get("version") != plugin["version"]:
        raise MarketplaceError(f"Codex plugin version mismatch: {name}")
    if manifest.get("author") != owner:
        raise MarketplaceError(f"Codex plugin author mismatch: {name}")
    if manifest.get("description") != plugin["description"]:
        raise MarketplaceError(f"Codex plugin description mismatch: {name}")
    if manifest.get("skills") != "./skills/":
        raise MarketplaceError(f"Codex plugin skills path must equal ./skills/: {name}")
    if manifest.get("interface") != {
        "displayName": plugin["displayName"],
        "shortDescription": plugin["description"],
    }:
        raise MarketplaceError(f"Codex plugin interface mismatch: {name}")
    payload_dir = plugin_dir / "skills" / name
    if not payload_dir.is_dir() or directory_files(payload_dir) != directory_files(
        skill_dir
    ):
        raise MarketplaceError(
            f"Codex plugin payload out of sync with canonical skill: {name}; "
            "run marketplace/sync.py"
        )


def validate_bundle_documentation(readme_path: Path, bundles: dict[str, Any]) -> None:
    """Require one documented install command per bundle in the README.

    Line-continuation backslashes collapse before matching, so wrapped
    commands stay valid.
    """
    try:
        readme = readme_path.read_text(encoding="utf-8")
    except OSError as error:
        raise MarketplaceError(f"unable to read README: {readme_path}") from error
    normalized = re.sub(r"\s+", " ", re.sub(r"\\\s*\n", " ", readme))
    for bundle_name, bundle in bundles.items():
        if bundle_name not in readme:
            raise MarketplaceError(f"README does not document bundle: {bundle_name}")
        command = "--skill " + " ".join(bundle["plugins"])
        if command not in normalized:
            raise MarketplaceError(f"README bundle command out of sync: {bundle_name}")


def validate_repository(root: Path, catalog_path: Path | None = None) -> dict[str, Any]:
    root = root.resolve()
    if not root.is_dir():
        raise MarketplaceError(f"repository root does not exist: {root}")
    catalog_path = catalog_path or (
        root / "modules/common/ai-tools/marketplace/catalog.json"
    )
    catalog = load_catalog(catalog_path)
    skills_dir = root / SKILLS_PATH
    discovered = discover_skills(skills_dir)
    validate_catalog_coverage(catalog, discovered)

    marketplace = catalog["marketplace"]
    owner = marketplace["owner"]
    codex_marketplace = load_json_object(root / CODEX_MARKETPLACE_PATH)
    claude_marketplace = load_json_object(root / CLAUDE_MARKETPLACE_PATH)
    for provider, payload in (
        ("Codex", codex_marketplace),
        ("Claude", claude_marketplace),
    ):
        if payload.get("name") != marketplace["name"]:
            raise MarketplaceError(
                f"{provider} marketplace name does not match catalog"
            )

    if codex_marketplace.get("interface") != {
        "displayName": marketplace["displayName"]
    }:
        raise MarketplaceError("Codex marketplace display name does not match catalog")
    if claude_marketplace.get("description") != marketplace["description"]:
        raise MarketplaceError("Claude marketplace description does not match catalog")
    if claude_marketplace.get("owner") != owner:
        raise MarketplaceError("Claude marketplace owner does not match catalog")

    codex_entries = require_plugin_entries(codex_marketplace, "Codex")
    claude_entries = require_plugin_entries(claude_marketplace, "Claude")
    expected_names = catalog_plugin_names(catalog)
    for provider, entries in (("Codex", codex_entries), ("Claude", claude_entries)):
        actual_names = [
            require_entry(entry, provider, index).get("name")
            for index, entry in enumerate(entries)
        ]
        if actual_names != expected_names:
            raise MarketplaceError(
                f"{provider} marketplace plugin order does not match catalog"
            )

    stray = sorted(
        skill_dir.name
        for skill_dir in skills_dir.iterdir()
        if (skill_dir / ".codex-plugin").exists()
        or (skill_dir / ".claude-plugin").exists()
    )
    if stray:
        raise MarketplaceError(
            "canonical skills must not contain plugin manifests: " + ", ".join(stray)
        )

    plugins_tree = root / PLUGINS_TREE_PATH
    for index, plugin in enumerate(catalog["plugins"]):
        name = plugin["name"]
        plugin_path = f"./{(PLUGINS_TREE_PATH / name).as_posix()}"
        skill = read_skill_frontmatter(discovered[name])
        codex_entry = require_entry(codex_entries[index], "Codex", index)
        claude_entry = require_entry(claude_entries[index], "Claude", index)
        validate_codex_entry(codex_entry, plugin, plugin_path)
        validate_claude_entry(claude_entry, plugin, plugin_path, owner)
        validate_codex_plugin(plugins_tree / name, discovered[name], plugin, owner)
        validate_claude_plugin(plugins_tree / name, plugin, owner)
        if not skill["description"]:
            raise MarketplaceError(f"skill description is empty: {name}")

    exposed = sorted(
        plugin_dir.name for plugin_dir in plugins_tree.iterdir() if plugin_dir.is_dir()
    )
    if exposed != sorted(expected_names):
        raise MarketplaceError("plugin tree does not match published catalog entries")

    bundles = catalog.get("bundles", {})
    if bundles:
        validate_bundle_documentation(catalog_path.parent / "README.md", bundles)

    return {
        "marketplace": marketplace["name"],
        "root": str(root),
        "plugins": len(expected_names),
        "excluded": catalog["excluded"],
        "bundles": {name: bundle["plugins"] for name, bundle in bundles.items()},
    }


def default_root() -> Path:
    return Path(__file__).resolve().parents[4]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Validate checked-in Codex and Claude skill marketplaces."
    )
    parser.add_argument("--root", type=Path, default=default_root())
    parser.add_argument("--catalog", type=Path)
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    result = validate_repository(args.root, args.catalog)
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    try:
        main()
    except MarketplaceError as error:
        print(f"marketplace error: {error}", file=sys.stderr)
        raise SystemExit(1) from error
