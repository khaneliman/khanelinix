#!/usr/bin/env python3
"""Report bounded .NET repository context without restoring, building, or invoking MSBuild."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any
from xml.etree import ElementTree

# Support dates from the .NET release policy. net6/net7 are already out of support.
TFM_SUPPORT = {
    "net6.0": ("EOL", "2024-11-12"),
    "net7.0": ("EOL", "2024-05-14"),
    "net8.0": ("LTS", "2026-11-10"),
    "net9.0": ("STS", "2026-11-10"),
    "net10.0": ("LTS", "2028-11-14"),
}

# TFM-implied C# default. An explicit LangVersion or an inherited props file overrides this,
# so the report tags which source won.
TFM_LANG_VERSION = {
    "net8.0": "12.0",
    "net9.0": "13.0",
    "net10.0": "14.0",
}

SDK_KINDS = {
    "Microsoft.NET.Sdk": "library-or-console",
    "Microsoft.NET.Sdk.Web": "web",
    "Microsoft.NET.Sdk.Razor": "razor-class-library",
    "Microsoft.NET.Sdk.BlazorWebAssembly": "blazor-webassembly",
    "Microsoft.NET.Sdk.Worker": "worker",
}

TEST_FRAMEWORK_PACKAGES = {
    "xunit": "xunit",
    "xunit.v3": "xunit.v3",
    "nunit": "nunit",
    "mstest": "mstest",
    "mstest.testframework": "mstest",
    "tunit": "tunit",
    "bunit": "bunit",
}

ANALYZER_PACKAGES = {
    "roslynator.analyzers",
    "stylecop.analyzers",
    "meziantou.analyzer",
    "sonaranalyzer.csharp",
    "microsoft.visualstudio.threading.analyzers",
    "asyncfixer",
    "microsoft.codeanalysis.banneddapianalyzers",
    "microsoft.codeanalysis.bannedapianalyzers",
    "microsoft.codeanalysis.publicapianalyzers",
    "microsoft.codeanalysis.netanalyzers",
}

# Assertion and mocking packages whose licensing or supply chain changed recently enough
# that the resolved version changes what is safe to recommend.
WATCHED_PACKAGES = {"fluentassertions", "moq"}

BOOL_PROPERTIES = (
    "Nullable",
    "ImplicitUsings",
    "TreatWarningsAsErrors",
    "EnforceCodeStyleInBuild",
    "GenerateDocumentationFile",
    "IsPackable",
    "IsTestProject",
    "IsAotCompatible",
    "PublishAot",
    "PublishTrimmed",
    "InvariantGlobalization",
    "UseArtifactsOutput",
    "BlazorDisableThrowNavigationException",
    "RequiresAspNetWebAssets",
    "TestingPlatformDotnetTestSupport",
    "UseMicrosoftTestingPlatformRunner",
    "EnableMicrosoftTestingPlatform",
)

TEXT_PROPERTIES = (
    "LangVersion",
    "WarningsAsErrors",
    "AnalysisLevel",
    "AnalysisMode",
    "RootNamespace",
    "AssemblyName",
    "OutputType",
)

SKIP_DIRECTORIES = {"bin", "obj", "node_modules", ".git", ".vs", "artifacts"}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "path",
        nargs="?",
        default=".",
        help="directory inside a .NET repository (default: current directory)",
    )
    parser.add_argument(
        "--json", action="store_true", help="emit JSON instead of Markdown"
    )
    return parser.parse_args()


def strip_namespace(tag: str) -> str:
    return tag.rsplit("}", 1)[-1] if "}" in tag else tag


def read_text_or_empty(path: Path) -> str:
    """Read a file, treating an unreadable one as absent rather than fatal."""
    try:
        return path.read_text(encoding="utf-8", errors="replace")
    except OSError:
        return ""


def parse_xml(path: Path) -> ElementTree.Element | None:
    try:
        return ElementTree.parse(path).getroot()
    except (ElementTree.ParseError, OSError):
        return None


def walk_files(root: Path, suffixes: tuple[str, ...]) -> list[Path]:
    found: list[Path] = []
    for candidate in sorted(root.rglob("*")):
        if any(part in SKIP_DIRECTORIES for part in candidate.parts):
            continue
        if candidate.is_file() and candidate.suffix in suffixes:
            found.append(candidate)
    return found


def read_properties(root: ElementTree.Element) -> dict[str, str]:
    """Collect PropertyGroup children. Later definitions win, matching MSBuild ordering."""
    properties: dict[str, str] = {}
    for group in root.iter():
        if strip_namespace(group.tag) != "PropertyGroup":
            continue
        for node in group:
            name = strip_namespace(node.tag)
            if node.text is not None:
                properties[name] = node.text.strip()
    return properties


def read_package_references(root: ElementTree.Element) -> list[dict[str, Any]]:
    packages: list[dict[str, Any]] = []
    for node in root.iter():
        if strip_namespace(node.tag) != "PackageReference":
            continue
        name = node.attrib.get("Include") or node.attrib.get("Update")
        if not name:
            continue
        packages.append(
            {
                "name": name,
                "version": node.attrib.get("Version"),
                "version_override": node.attrib.get("VersionOverride"),
            }
        )
    return sorted(packages, key=lambda item: item["name"].lower())


def read_project_references(root: ElementTree.Element) -> list[str]:
    references = [
        node.attrib["Include"]
        for node in root.iter()
        if strip_namespace(node.tag) == "ProjectReference" and "Include" in node.attrib
    ]
    return sorted(references)


def nearest_props(project_dir: Path, repo_root: Path, filename: str) -> Path | None:
    """MSBuild imports only the first matching file found walking up, not every ancestor."""
    current = project_dir
    while True:
        candidate = current / filename
        if candidate.is_file():
            return candidate
        if current == repo_root or current.parent == current:
            return None
        current = current.parent


def load_central_packages(props: Path | None, repo_root: Path) -> dict[str, Any]:
    """Read one Directory.Packages.props.

    NuGet evaluates the closest file to each project, so the caller resolves which
    file applies rather than assuming a single repository-wide one. Package IDs are
    case-insensitive, so versions are keyed in lower case.
    """
    if props is None:
        return {"enabled": False, "path": None, "versions": {}}

    root = parse_xml(props)
    if root is None:
        return {"enabled": False, "path": str(props), "versions": {}}

    properties = read_properties(root)
    versions = {
        node.attrib["Include"].lower(): node.attrib.get("Version")
        for node in root.iter()
        if strip_namespace(node.tag) == "PackageVersion" and "Include" in node.attrib
    }
    return {
        "enabled": properties.get("ManagePackageVersionsCentrally", "").lower()
        == "true",
        "path": str(props.relative_to(repo_root)),
        "transitive_pinning": properties.get(
            "CentralPackageTransitivePinningEnabled", ""
        ).lower()
        == "true",
        "versions": versions,
    }


def inherited_properties(project_dir: Path, repo_root: Path) -> dict[str, str]:
    """Read the nearest automatically imported Directory.Build.props.

    MSBuild imports only the first file found walking up, not a merge of every
    ancestor. Values here are overlaid by project-local ones, which matches import
    order for the simple case. Conditions are not evaluated.
    """
    props = nearest_props(project_dir, repo_root, "Directory.Build.props")
    if props is None:
        return {}
    root = parse_xml(props)
    return read_properties(root) if root is not None else {}


def read_global_json_runner(repo_root: Path) -> dict[str, Any]:
    """Read the runner selected by root global.json only.

    Microsoft.Testing.Platform is opt-in per repository, not an SDK default. Verified
    on SDK 10.0.400: `dotnet test` is the VSTest command unless global.json selects
    the newer runner. This reads only that one signal. Project-level MSBuild
    properties and MTP-only packages are reported separately, because resolving them
    for certain needs real MSBuild evaluation.
    """
    global_json = repo_root / "global.json"
    if not global_json.is_file():
        return {"runner": "VSTest", "source": "default", "global_json": False}
    try:
        payload = json.loads(global_json.read_text(encoding="utf-8"))
    except (json.JSONDecodeError, OSError):
        return {
            "runner": "VSTest",
            "source": "unreadable global.json",
            "global_json": True,
        }
    if not isinstance(payload, dict):
        return {
            "runner": "VSTest",
            "source": "unexpected global.json shape",
            "global_json": True,
        }

    test_section = payload.get("test")
    runner = test_section.get("runner") if isinstance(test_section, dict) else None
    if runner:
        return {"runner": runner, "source": "global.json", "global_json": True}
    return {"runner": "VSTest", "source": "default", "global_json": True}


# Packages that only run under Microsoft.Testing.Platform, so their presence
# contradicts a VSTest reading even when global.json says nothing.
MTP_ONLY_PACKAGES = {"tunit", "tunit.engine"}

MTP_PROPERTIES = (
    "TestingPlatformDotnetTestSupport",
    "UseMicrosoftTestingPlatformRunner",
    "EnableMicrosoftTestingPlatform",
)


def summarize_test_runner(
    global_json_runner: dict[str, Any], projects: list[dict[str, Any]]
) -> dict[str, Any]:
    """Combine the global.json signal with per-project evidence.

    Reports disagreement rather than resolving it. Deciding the effective runner for
    a project needs real MSBuild evaluation, which this script deliberately avoids.
    """
    property_projects = [
        project["path"]
        for project in projects
        if any(
            project.get("properties", {}).get(name, "").lower() == "true"
            for name in MTP_PROPERTIES
        )
    ]
    package_projects = [
        project["path"]
        for project in projects
        if any(
            item["name"].lower() in MTP_ONLY_PACKAGES
            for item in project.get("packages", [])
        )
    ]

    evidence = sorted(set(property_projects) | set(package_projects))
    selected = global_json_runner["runner"]
    if evidence and selected == "VSTest":
        confidence = "conflicting"
    elif evidence or global_json_runner["global_json"]:
        confidence = "supported"
    else:
        confidence = "assumed-default"

    return {
        "global_json_runner": selected,
        "global_json_source": global_json_runner["source"],
        "global_json_present": global_json_runner["global_json"],
        "testing_platform_evidence": evidence,
        "confidence": confidence,
    }


COMMENT_PATTERNS = (
    re.compile(r"@\*.*?\*@", re.DOTALL),  # Razor comment
    re.compile(r"/\*.*?\*/", re.DOTALL),  # C# block comment
    re.compile(r"^[ \t]*//.*$", re.MULTILINE),  # C# line comment
    re.compile(r"<!--.*?-->", re.DOTALL),  # HTML comment
)


def strip_comments(text: str) -> str:
    """Remove comments so a commented-out registration is not read as a fact.

    This is lexical, not a parser. A string literal containing one of these markers
    can still be stripped, and a registration inside a string literal is still
    matched. Treat Blazor fields as strong hints rather than proof.
    """
    for pattern in COMMENT_PATTERNS:
        text = pattern.sub(" ", text)
    return text


def detect_blazor(repo_root: Path) -> dict[str, Any]:
    """Classify hosting model and render mode from source, not from package names."""
    sources = walk_files(repo_root, (".cs", ".razor", ".cshtml"))
    blob_parts: list[str] = []
    razor_parts: list[str] = []
    for path in sources:
        try:
            text = strip_comments(path.read_text(encoding="utf-8", errors="replace"))
        except OSError:
            continue
        blob_parts.append(text)
        if path.suffix == ".razor":
            razor_parts.append(text)
    blob = "\n".join(blob_parts)
    razor = "\n".join(razor_parts)

    if re.search(r"AddRazorComponents\s*\(|MapRazorComponents\s*<", blob):
        hosting = "blazor-web-app"
    elif re.search(r"AddServerSideBlazor\s*\(|MapBlazorHub\s*\(", blob):
        hosting = "legacy-blazor-server"
    elif any(
        'Sdk="Microsoft.NET.Sdk.BlazorWebAssembly"' in read_text_or_empty(path)
        for path in walk_files(repo_root, (".csproj",))
    ):
        hosting = "standalone-webassembly"
    else:
        hosting = None

    registered = sorted(
        set(
            re.findall(
                r"Add(?:Interactive(?:Server|WebAssembly|Auto))(?:Components|RenderMode)",
                blob,
            )
        )
    )
    declared = sorted(
        set(
            re.findall(
                r"@rendermode.*?(InteractiveServer|InteractiveWebAssembly|InteractiveAuto)",
                razor,
            )
        )
    )

    if re.search(r"<Routes[^>]*@rendermode", razor):
        scope = "global"
    elif "@rendermode" in razor:
        scope = "per-component"
    elif hosting:
        scope = "static-ssr-only"
    else:
        scope = None

    return {
        "hosting_model": hosting,
        "registered_interactivity": registered,
        "declared_render_modes": declared,
        "render_mode_scope": scope,
        "prerender_disabled_sites": len(re.findall(r"prerender:\s*false", blob)),
        "component_count": len(razor_parts),
    }


def classify_project(
    path: Path,
    repo_root: Path,
) -> dict[str, Any]:
    root = parse_xml(path)
    if root is None:
        return {"path": str(path.relative_to(repo_root)), "unreadable": True}

    inherited = inherited_properties(path.parent, repo_root)
    own = read_properties(root)
    # Project-local definitions win over the imported props file.
    properties = inherited | own
    inherited_only = sorted(set(inherited) - set(own))

    central = load_central_packages(
        nearest_props(path.parent, repo_root, "Directory.Packages.props"), repo_root
    )
    sdk_attribute = root.attrib.get("Sdk", "")
    packages = read_package_references(root)
    package_names = {item["name"].lower() for item in packages}

    frameworks_raw = properties.get("TargetFrameworks") or properties.get(
        "TargetFramework", ""
    )
    frameworks = [item.strip() for item in frameworks_raw.split(";") if item.strip()]

    lang_version = properties.get("LangVersion")
    if lang_version:
        lang_source = "explicit"
    else:
        lang_version = next(
            (TFM_LANG_VERSION[tfm] for tfm in frameworks if tfm in TFM_LANG_VERSION),
            None,
        )
        lang_source = "tfm-default" if lang_version else "unknown"

    test_frameworks = sorted(
        {
            label
            for key, label in TEST_FRAMEWORK_PACKAGES.items()
            if key in package_names
        }
    )

    resolved_packages = []
    for item in packages:
        version = item["version"] or item["version_override"]
        source = "explicit"
        if version is None and central["enabled"]:
            version = central["versions"].get(item["name"].lower())
            source = "central"
        elif item["version_override"]:
            source = "version-override"
        elif version is None:
            source = "unresolved"
        resolved_packages.append(
            {"name": item["name"], "version": version, "source": source}
        )

    record: dict[str, Any] = {
        "path": str(path.relative_to(repo_root)),
        "sdk": sdk_attribute,
        "sdk_kind": SDK_KINDS.get(sdk_attribute, "unknown"),
        "target_frameworks": frameworks,
        "lang_version": lang_version,
        "lang_version_source": lang_source,
        "properties": {
            name: properties[name] for name in BOOL_PROPERTIES if name in properties
        }
        | {name: properties[name] for name in TEXT_PROPERTIES if name in properties},
        "packages": resolved_packages,
        "project_references": read_project_references(root),
        "test_frameworks": test_frameworks,
        "is_test_project": bool(test_frameworks)
        or properties.get("IsTestProject", "").lower() == "true",
        "analyzers": sorted(package_names & ANALYZER_PACKAGES),
        "watched_packages": [
            {"name": item["name"], "version": item["version"]}
            for item in resolved_packages
            if item["name"].lower() in WATCHED_PACKAGES
        ],
        "directory_build_props": None,
        "inherited_property_names": inherited_only,
        "central_packages_props": central["path"],
    }

    props = nearest_props(path.parent, repo_root, "Directory.Build.props")
    if props is not None:
        record["directory_build_props"] = str(props.relative_to(repo_root))
    return record


def collect(repo_root: Path) -> dict[str, Any]:
    projects_paths = walk_files(repo_root, (".csproj", ".fsproj"))
    projects = [classify_project(path, repo_root) for path in projects_paths]
    central_files = sorted(
        {
            project["central_packages_props"]
            for project in projects
            if project.get("central_packages_props")
        }
    )
    central = load_central_packages(
        nearest_props(repo_root, repo_root, "Directory.Packages.props")
        or next(
            (
                path
                for path in walk_files(repo_root, (".props",))
                if path.name == "Directory.Packages.props"
            ),
            None,
        ),
        repo_root,
    )
    central["applies_to_files"] = central_files

    frameworks = sorted(
        {tfm for project in projects for tfm in project.get("target_frameworks", [])}
    )
    eol = [
        {
            "framework": tfm,
            "phase": TFM_SUPPORT[tfm][0],
            "support_ends": TFM_SUPPORT[tfm][1],
        }
        for tfm in frameworks
        if tfm in TFM_SUPPORT and TFM_SUPPORT[tfm][0] == "EOL"
    ]
    expiring = [
        {
            "framework": tfm,
            "phase": TFM_SUPPORT[tfm][0],
            "support_ends": TFM_SUPPORT[tfm][1],
        }
        for tfm in frameworks
        if tfm in TFM_SUPPORT and TFM_SUPPORT[tfm][0] != "EOL"
    ]

    solutions = walk_files(repo_root, (".sln", ".slnx"))
    nuget_configs = [
        path
        for path in walk_files(repo_root, (".config",))
        if path.name.lower() == "nuget.config"
    ]

    return {
        "root": str(repo_root),
        "solutions": [
            {
                "path": str(path.relative_to(repo_root)),
                "format": path.suffix.lstrip("."),
            }
            for path in solutions
        ],
        "central_package_management": central,
        "test_runner": summarize_test_runner(
            read_global_json_runner(repo_root), projects
        ),
        "blazor": detect_blazor(repo_root),
        "target_frameworks": frameworks,
        "frameworks_out_of_support": eol,
        "frameworks_in_support": expiring,
        "projects": projects,
        "nuget_config_paths": [
            str(path.relative_to(repo_root)) for path in nuget_configs
        ],
        "local_tool_manifest": (repo_root / ".config" / "dotnet-tools.json").is_file(),
        "lock_files": [
            str(path.relative_to(repo_root))
            for path in walk_files(repo_root, (".json",))
            if path.name == "packages.lock.json"
        ],
    }


def render_markdown(data: dict[str, Any]) -> str:
    lines = [f"# .NET context for {data['root']}", ""]

    solutions = data["solutions"] or []
    formats = sorted({item["format"] for item in solutions})
    lines.append(
        f"- Solutions: {len(solutions)}"
        + (f" (format: {', '.join(formats)})" if formats else "")
    )

    central = data["central_package_management"]
    lines.append(
        "- Central package management: "
        + (
            "enabled at " + str(central["path"])
            if central["enabled"]
            else "not enabled"
        )
    )

    runner = data["test_runner"]
    lines.append(
        f"- Test runner from global.json: {runner['global_json_runner']}"
        f" (via {runner['global_json_source']}, confidence {runner['confidence']})"
    )
    if runner["testing_platform_evidence"]:
        lines.append(
            "- Testing-platform evidence in: "
            + ", ".join(runner["testing_platform_evidence"])
        )
    if runner["confidence"] == "conflicting":
        lines.append(
            "- WARNING: global.json says VSTest but project evidence says otherwise."
            " Confirm the runner before choosing coverage flags."
        )

    lines.append(f"- Projects: {len(data['projects'])}")
    lines.append(
        f"- Target frameworks: {', '.join(data['target_frameworks']) or 'none found'}"
    )

    for item in data["frameworks_out_of_support"]:
        lines.append(
            f"- OUT OF SUPPORT: {item['framework']} ended {item['support_ends']}"
        )
    for item in data["frameworks_in_support"]:
        lines.append(
            f"- Support ends: {item['framework']} on {item['support_ends']} ({item['phase']})"
        )

    blazor = data["blazor"]
    if blazor["hosting_model"]:
        lines.extend(
            [
                "",
                "## Blazor",
                "",
                f"- Hosting model: {blazor['hosting_model']}",
                f"- Render mode scope: {blazor['render_mode_scope']}",
                f"- Registered interactivity: {', '.join(blazor['registered_interactivity']) or 'none'}",
                f"- Declared render modes: {', '.join(blazor['declared_render_modes']) or 'none'}",
                f"- Components: {blazor['component_count']}",
                f"- Prerender opt-outs: {blazor['prerender_disabled_sites']}",
            ]
        )

    watched = [
        (project["path"], package)
        for project in data["projects"]
        for package in project.get("watched_packages", [])
    ]
    if watched:
        lines.extend(["", "## Packages needing a version check", ""])
        for project_path, package in watched:
            lines.append(
                f"- {package['name']} {package['version'] or 'unresolved'} in {project_path}"
            )

    lines.extend(["", "## Projects", ""])
    for project in data["projects"]:
        if project.get("unreadable"):
            lines.append(f"- {project['path']}: unreadable")
            continue
        frameworks = ", ".join(project["target_frameworks"]) or "unknown"
        lines.append(
            f"- {project['path']} [{project['sdk_kind']}] {frameworks}"
            + (" (test)" if project["is_test_project"] else "")
        )
    return "\n".join(lines) + "\n"


def main() -> int:
    args = parse_args()
    root = Path(args.path).resolve()
    if root.is_file():
        # Accept a project or solution file and scan the directory holding it.
        root = root.parent
    if not root.is_dir():
        # A nonexistent path must fail rather than silently scanning its parent.
        print(f"not a directory: {args.path}", file=sys.stderr)
        return 2

    data = collect(root)
    if args.json:
        print(json.dumps(data, indent=2, sort_keys=True))
    else:
        print(render_markdown(data), end="")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
