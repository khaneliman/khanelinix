#!/usr/bin/env python3
"""Report bounded Rust workspace context without creating a Cargo.lock."""

from __future__ import annotations

import argparse
import glob
import json
import subprocess
import sys
import tomllib
from pathlib import Path
from typing import Any

CONFIG_PATHS = (
    "Cargo.lock",
    "rust-toolchain.toml",
    "rust-toolchain",
    "rustfmt.toml",
    ".rustfmt.toml",
    "clippy.toml",
    ".clippy.toml",
    "deny.toml",
    ".cargo/config.toml",
    ".cargo/config",
    ".config/nextest.toml",
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "path",
        nargs="?",
        default=".",
        help="Cargo.toml or directory inside a Rust project (default: current directory)",
    )
    parser.add_argument(
        "--json", action="store_true", help="emit JSON instead of Markdown"
    )
    return parser.parse_args()


def find_manifest(raw_path: str) -> Path:
    path = Path(raw_path).expanduser().resolve()
    if path.is_file():
        if path.name != "Cargo.toml":
            raise ValueError(f"expected Cargo.toml, got {path}")
        return path

    current = path
    while True:
        candidate = current / "Cargo.toml"
        if candidate.is_file():
            return candidate
        if current.parent == current:
            break
        current = current.parent
    raise ValueError(f"no Cargo.toml found from {path}")


def load_toml(path: Path) -> dict[str, Any]:
    with path.open("rb") as handle:
        return tomllib.load(handle)


def command_version(command: str) -> str | None:
    try:
        result = subprocess.run(
            [command, "--version"],
            check=True,
            capture_output=True,
            text=True,
            timeout=10,
        )
    except (FileNotFoundError, subprocess.SubprocessError):
        return None
    return result.stdout.strip() or result.stderr.strip() or None


def lockfile_for(manifest: Path) -> Path | None:
    current = manifest.parent
    while True:
        lockfile = current / "Cargo.lock"
        if lockfile.is_file():
            return lockfile
        if (current / ".git").exists() or current.parent == current:
            return None
        current = current.parent


def cargo_metadata(manifest: Path) -> dict[str, Any] | None:
    if lockfile_for(manifest) is None:
        return None
    try:
        result = subprocess.run(
            [
                "cargo",
                "metadata",
                "--format-version",
                "1",
                "--no-deps",
                "--locked",
                "--manifest-path",
                str(manifest),
            ],
            check=True,
            capture_output=True,
            text=True,
            timeout=60,
        )
    except (FileNotFoundError, subprocess.SubprocessError):
        return None
    return json.loads(result.stdout)


def relative(path: Path, root: Path) -> str:
    try:
        return str(path.resolve().relative_to(root.resolve())) or "."
    except ValueError:
        return str(path.resolve())


def dependency_rows(manifest_data: dict[str, Any]) -> list[dict[str, str]]:
    rows: list[dict[str, str]] = []
    sections = ("dependencies", "dev-dependencies", "build-dependencies")

    def collect(section: dict[str, Any], kind: str) -> None:
        for name, value in section.items():
            if isinstance(value, str):
                requirement = value
                package = name
            elif isinstance(value, dict):
                requirement = str(value.get("version", "path/git/workspace"))
                package = str(value.get("package", name))
            else:
                requirement = "unknown"
                package = name
            rows.append({"name": package, "requirement": requirement, "kind": kind})

    for section_name in sections:
        collect(
            manifest_data.get(section_name, {}),
            section_name.removesuffix("-dependencies"),
        )
    for target in manifest_data.get("target", {}).values():
        if not isinstance(target, dict):
            continue
        for section_name in sections:
            collect(
                target.get(section_name, {}),
                f"target-{section_name.removesuffix('-dependencies')}",
            )
    return rows


def static_manifests(root_manifest: Path, root_data: dict[str, Any]) -> list[Path]:
    workspace = root_data.get("workspace", {})
    manifests: set[Path] = set()
    if "package" in root_data:
        manifests.add(root_manifest)

    for member in workspace.get("members", []):
        pattern = root_manifest.parent / member
        for match in glob.glob(str(pattern), recursive=True):
            path = Path(match)
            candidate = path if path.name == "Cargo.toml" else path / "Cargo.toml"
            if candidate.is_file():
                manifests.add(candidate.resolve())

    excluded: set[Path] = set()
    for member in workspace.get("exclude", []):
        pattern = root_manifest.parent / member
        for match in glob.glob(str(pattern), recursive=True):
            path = Path(match)
            candidate = path if path.name == "Cargo.toml" else path / "Cargo.toml"
            excluded.add(candidate.resolve())

    return sorted(manifests - excluded)


def static_target_kinds(manifest: Path, data: dict[str, Any]) -> list[str]:
    kinds: set[str] = set()
    if "lib" in data or (manifest.parent / "src/lib.rs").is_file():
        kinds.add(str(data.get("lib", {}).get("crate-type", ["lib"])[0]))
    if data.get("bin") or (manifest.parent / "src/main.rs").is_file():
        kinds.add("bin")
    if data.get("example") or (manifest.parent / "examples").is_dir():
        kinds.add("example")
    if data.get("test") or (manifest.parent / "tests").is_dir():
        kinds.add("test")
    if data.get("bench") or (manifest.parent / "benches").is_dir():
        kinds.add("bench")
    return sorted(kinds)


def inherited_value(value: Any, fallback: str) -> Any:
    if isinstance(value, dict) and value.get("workspace") is True:
        return fallback
    return value if value is not None else fallback


def package_from_static(manifest: Path, root: Path) -> dict[str, Any]:
    data = load_toml(manifest)
    package = data.get("package", {})
    dependencies = dependency_rows(data)
    return {
        "name": package.get("name", manifest.parent.name),
        "version": inherited_value(package.get("version"), "workspace"),
        "manifest": relative(manifest, root),
        "edition": inherited_value(package.get("edition"), "workspace/default"),
        "rust_version": inherited_value(
            package.get("rust-version"), "workspace/unspecified"
        ),
        "target_kinds": static_target_kinds(manifest, data),
        "features": sorted(data.get("features", {}).keys()),
        "dependency_count": len(dependencies),
    }


def package_from_metadata(package: dict[str, Any], root: Path) -> dict[str, Any]:
    dependencies = package.get("dependencies", [])
    return {
        "name": package["name"],
        "version": package["version"],
        "manifest": relative(Path(package["manifest_path"]), root),
        "edition": package.get("edition", "unspecified"),
        "rust_version": package.get("rust_version") or "unspecified",
        "target_kinds": sorted(
            {kind for target in package.get("targets", []) for kind in target["kind"]}
        ),
        "features": sorted(package.get("features", {}).keys()),
        "dependency_count": len(dependencies),
    }


def collect_context(manifest: Path) -> dict[str, Any]:
    metadata = cargo_metadata(manifest)
    if metadata is not None:
        root = Path(metadata["workspace_root"])
        root_manifest = root / "Cargo.toml"
        root_data = load_toml(root_manifest)
        packages = [
            package_from_metadata(package, root) for package in metadata["packages"]
        ]
        discovery = "cargo metadata --locked --no-deps"
    else:
        root_manifest = manifest
        root = root_manifest.parent
        root_data = load_toml(root_manifest)
        manifests = static_manifests(root_manifest, root_data)
        if not manifests and "package" in root_data:
            manifests = [root_manifest]
        packages = [package_from_static(item, root) for item in manifests]
        discovery = "static TOML fallback"

    workspace = root_data.get("workspace", {})
    profiles = {
        name: sorted(value.keys()) if isinstance(value, dict) else []
        for name, value in root_data.get("profile", {}).items()
    }
    configs = [path for path in CONFIG_PATHS if (root / path).exists()]
    return {
        "manifest": relative(manifest, root),
        "workspace_root": str(root.resolve()),
        "discovery": discovery,
        "resolver": workspace.get(
            "resolver", root_data.get("package", {}).get("resolver", "unspecified")
        ),
        "workspace_members": len(packages),
        "packages": sorted(packages, key=lambda package: package["name"]),
        "profiles": profiles,
        "config_files": configs,
        "toolchain": {
            "cargo": command_version("cargo"),
            "rustc": command_version("rustc"),
        },
    }


def markdown(context: dict[str, Any]) -> str:
    lines = [
        "# Rust project context",
        "",
        f"- Workspace root: `{context['workspace_root']}`",
        f"- Manifest: `{context['manifest']}`",
        f"- Discovery: {context['discovery']}",
        f"- Resolver: `{context['resolver']}`",
        f"- Workspace packages: {context['workspace_members']}",
        f"- Cargo: `{context['toolchain']['cargo'] or 'unavailable'}`",
        f"- Rustc: `{context['toolchain']['rustc'] or 'unavailable'}`",
        f"- Config files: {', '.join(f'`{item}`' for item in context['config_files']) or 'none detected'}",
        "",
        "## Packages",
        "",
        "| Package | Version | Edition | MSRV | Targets | Features | Direct deps |",
        "| --- | --- | --- | --- | --- | ---: | ---: |",
    ]
    for package in context["packages"]:
        lines.append(
            f"| `{package['name']}` | `{package['version']}` | `{package['edition']}` | "
            f"`{package['rust_version']}` | {', '.join(package['target_kinds']) or '-'} | "
            f"{len(package['features'])} | {package['dependency_count']} |"
        )

    lines.extend(["", "## Profiles", ""])
    if context["profiles"]:
        for name, keys in sorted(context["profiles"].items()):
            lines.append(
                f"- `{name}`: {', '.join(f'`{key}`' for key in keys) or 'declared'}"
            )
    else:
        lines.append("- No workspace profile overrides detected")
    return "\n".join(lines)


def main() -> int:
    args = parse_args()
    try:
        context = collect_context(find_manifest(args.path))
    except (
        OSError,
        ValueError,
        tomllib.TOMLDecodeError,
        json.JSONDecodeError,
    ) as error:
        print(f"project-context: {error}", file=sys.stderr)
        return 2

    if args.json:
        print(json.dumps(context, indent=2, sort_keys=True))
    else:
        print(markdown(context))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
