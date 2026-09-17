from __future__ import annotations

import json
import subprocess
import tempfile
import unittest
from pathlib import Path
from typing import Any

SKILL = Path(__file__).parents[1]
CONTEXT = SKILL / "scripts" / "project-context.py"

WEB_SDK = 'Sdk="Microsoft.NET.Sdk.Web"'


def run_context(root: Path) -> dict[str, Any]:
    result = subprocess.run(
        ["python3", "-P", str(CONTEXT), str(root), "--json"],
        check=False,
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        raise AssertionError(result.stderr)
    return json.loads(result.stdout)


def write(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")


class ProjectContextTests(unittest.TestCase):
    def test_reads_target_framework_and_sdk_kind(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            write(
                root / "Api" / "Api.csproj",
                f"<Project {WEB_SDK}><PropertyGroup>"
                "<TargetFramework>net10.0</TargetFramework>"
                "<Nullable>enable</Nullable>"
                "</PropertyGroup></Project>",
            )
            data = run_context(root)

            self.assertEqual(["net10.0"], data["target_frameworks"])
            project = data["projects"][0]
            self.assertEqual("web", project["sdk_kind"])
            self.assertEqual("14.0", project["lang_version"])
            self.assertEqual("tfm-default", project["lang_version_source"])

    def test_explicit_lang_version_beats_tfm_default(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            write(
                root / "Lib" / "Lib.csproj",
                '<Project Sdk="Microsoft.NET.Sdk"><PropertyGroup>'
                "<TargetFramework>net10.0</TargetFramework>"
                "<LangVersion>11.0</LangVersion>"
                "</PropertyGroup></Project>",
            )
            project = run_context(root)["projects"][0]

            self.assertEqual("11.0", project["lang_version"])
            self.assertEqual("explicit", project["lang_version_source"])

    def test_flags_out_of_support_frameworks(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            write(
                root / "Old" / "Old.csproj",
                '<Project Sdk="Microsoft.NET.Sdk"><PropertyGroup>'
                "<TargetFramework>net6.0</TargetFramework>"
                "</PropertyGroup></Project>",
            )
            data = run_context(root)

            self.assertEqual(
                [{"framework": "net6.0", "phase": "EOL", "support_ends": "2024-11-12"}],
                data["frameworks_out_of_support"],
            )

    def test_central_package_management_resolves_versions(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            write(
                root / "Directory.Packages.props",
                "<Project><PropertyGroup>"
                "<ManagePackageVersionsCentrally>true</ManagePackageVersionsCentrally>"
                "</PropertyGroup><ItemGroup>"
                '<PackageVersion Include="Serilog" Version="4.2.0" />'
                "</ItemGroup></Project>",
            )
            write(
                root / "Api" / "Api.csproj",
                f"<Project {WEB_SDK}><PropertyGroup>"
                "<TargetFramework>net10.0</TargetFramework>"
                "</PropertyGroup><ItemGroup>"
                '<PackageReference Include="Serilog" />'
                "</ItemGroup></Project>",
            )
            data = run_context(root)

            self.assertTrue(data["central_package_management"]["enabled"])
            package = data["projects"][0]["packages"][0]
            self.assertEqual("4.2.0", package["version"])
            self.assertEqual("central", package["source"])

    def test_test_runner_defaults_to_vstest_without_global_json(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            write(
                root / "T" / "T.csproj",
                '<Project Sdk="Microsoft.NET.Sdk"><PropertyGroup>'
                "<TargetFramework>net10.0</TargetFramework>"
                "</PropertyGroup></Project>",
            )
            runner = run_context(root)["test_runner"]

            self.assertEqual("VSTest", runner["global_json_runner"])
            self.assertFalse(runner["global_json_present"])
            self.assertEqual("assumed-default", runner["confidence"])

    def test_global_json_selects_testing_platform(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            write(
                root / "global.json",
                json.dumps({"test": {"runner": "Microsoft.Testing.Platform"}}),
            )
            write(
                root / "T" / "T.csproj",
                '<Project Sdk="Microsoft.NET.Sdk"><PropertyGroup>'
                "<TargetFramework>net10.0</TargetFramework>"
                "</PropertyGroup></Project>",
            )
            runner = run_context(root)["test_runner"]

            self.assertEqual("Microsoft.Testing.Platform", runner["global_json_runner"])
            self.assertEqual("global.json", runner["global_json_source"])

    def test_detects_global_render_mode_blazor_web_app(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            write(
                root / "Web" / "Web.csproj",
                f"<Project {WEB_SDK}><PropertyGroup>"
                "<TargetFramework>net10.0</TargetFramework>"
                "</PropertyGroup></Project>",
            )
            write(
                root / "Web" / "Program.cs",
                "builder.Services.AddRazorComponents()"
                ".AddInteractiveServerComponents();\n"
                "app.MapRazorComponents<App>().AddInteractiveServerRenderMode();\n",
            )
            write(
                root / "Web" / "App.razor",
                '<Routes @rendermode="InteractiveServer" />\n',
            )
            blazor = run_context(root)["blazor"]

            self.assertEqual("blazor-web-app", blazor["hosting_model"])
            self.assertEqual("global", blazor["render_mode_scope"])
            self.assertIn("InteractiveServer", blazor["declared_render_modes"])

    def test_detects_per_component_islands_and_prerender_opt_out(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            write(
                root / "Web" / "Web.csproj",
                f"<Project {WEB_SDK}><PropertyGroup>"
                "<TargetFramework>net10.0</TargetFramework>"
                "</PropertyGroup></Project>",
            )
            write(
                root / "Web" / "Program.cs",
                "builder.Services.AddRazorComponents()"
                ".AddInteractiveWebAssemblyComponents();\n",
            )
            write(root / "Web" / "Counter.razor", "@rendermode InteractiveAuto\n")
            write(
                root / "Web" / "Grid.razor",
                "@rendermode @(new InteractiveServerRenderMode(prerender: false))\n",
            )
            blazor = run_context(root)["blazor"]

            self.assertEqual("per-component", blazor["render_mode_scope"])
            self.assertEqual(
                ["InteractiveAuto", "InteractiveServer"],
                blazor["declared_render_modes"],
            )
            self.assertEqual(1, blazor["prerender_disabled_sites"])

    def test_detects_legacy_blazor_server(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            write(
                root / "Web" / "Web.csproj",
                f"<Project {WEB_SDK}><PropertyGroup>"
                "<TargetFramework>net8.0</TargetFramework>"
                "</PropertyGroup></Project>",
            )
            write(
                root / "Web" / "Startup.cs",
                "services.AddServerSideBlazor();\nendpoints.MapBlazorHub();\n",
            )
            blazor = run_context(root)["blazor"]

            self.assertEqual("legacy-blazor-server", blazor["hosting_model"])

    def test_reports_no_blazor_for_plain_api(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            write(
                root / "Api" / "Api.csproj",
                f"<Project {WEB_SDK}><PropertyGroup>"
                "<TargetFramework>net10.0</TargetFramework>"
                "</PropertyGroup></Project>",
            )
            write(root / "Api" / "Program.cs", 'app.MapGet("/", () => "ok");\n')
            blazor = run_context(root)["blazor"]

            self.assertIsNone(blazor["hosting_model"])
            self.assertIsNone(blazor["render_mode_scope"])

    def test_directory_build_props_resolves_to_nearest_only(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            write(root / "Directory.Build.props", "<Project />")
            write(root / "src" / "Directory.Build.props", "<Project />")
            write(
                root / "src" / "Api" / "Api.csproj",
                f"<Project {WEB_SDK}><PropertyGroup>"
                "<TargetFramework>net10.0</TargetFramework>"
                "</PropertyGroup></Project>",
            )
            project = run_context(root)["projects"][0]

            self.assertEqual(
                str(Path("src") / "Directory.Build.props"),
                project["directory_build_props"],
            )

    def test_flags_watched_packages_with_resolved_version(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            write(
                root / "T" / "T.csproj",
                '<Project Sdk="Microsoft.NET.Sdk"><PropertyGroup>'
                "<TargetFramework>net10.0</TargetFramework>"
                "</PropertyGroup><ItemGroup>"
                '<PackageReference Include="FluentAssertions" Version="8.1.0" />'
                '<PackageReference Include="xunit" Version="2.9.2" />'
                "</ItemGroup></Project>",
            )
            project = run_context(root)["projects"][0]

            self.assertEqual(
                [{"name": "FluentAssertions", "version": "8.1.0"}],
                project["watched_packages"],
            )
            self.assertEqual(["xunit"], project["test_frameworks"])
            self.assertTrue(project["is_test_project"])

    def test_ignores_build_output_directories(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            write(
                root / "Api" / "Api.csproj",
                f"<Project {WEB_SDK}><PropertyGroup>"
                "<TargetFramework>net10.0</TargetFramework>"
                "</PropertyGroup></Project>",
            )
            write(
                root / "Api" / "obj" / "Stale.csproj",
                '<Project Sdk="Microsoft.NET.Sdk"><PropertyGroup>'
                "<TargetFramework>net6.0</TargetFramework>"
                "</PropertyGroup></Project>",
            )
            data = run_context(root)

            self.assertEqual(1, len(data["projects"]))
            self.assertEqual([], data["frameworks_out_of_support"])

    def test_does_not_write_into_the_repository(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            write(
                root / "Api" / "Api.csproj",
                f"<Project {WEB_SDK}><PropertyGroup>"
                "<TargetFramework>net10.0</TargetFramework>"
                "</PropertyGroup></Project>",
            )
            before = sorted(path.name for path in root.rglob("*"))
            run_context(root)
            after = sorted(path.name for path in root.rglob("*"))

            self.assertEqual(before, after)

    def test_realistic_blazor_web_app_solution(self) -> None:
        """Server plus .Client plus tests, with central versions and an opted-in runner."""
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            write(root / "App.sln", "Microsoft Visual Studio Solution File\n")
            write(
                root / "global.json",
                json.dumps(
                    {
                        "sdk": {"version": "10.0.400"},
                        "test": {"runner": "Microsoft.Testing.Platform"},
                    }
                ),
            )
            write(
                root / "Directory.Packages.props",
                "<Project><PropertyGroup>"
                "<ManagePackageVersionsCentrally>true</ManagePackageVersionsCentrally>"
                "</PropertyGroup><ItemGroup>"
                '<PackageVersion Include="FluentAssertions" Version="8.2.0" />'
                '<PackageVersion Include="xunit" Version="2.9.2" />'
                "</ItemGroup></Project>",
            )
            write(
                root / "App" / "App.csproj",
                f"<Project {WEB_SDK}><PropertyGroup>"
                "<TargetFramework>net10.0</TargetFramework>"
                "<BlazorDisableThrowNavigationException>true"
                "</BlazorDisableThrowNavigationException>"
                "</PropertyGroup></Project>",
            )
            write(
                root / "App" / "Program.cs",
                "builder.Services.AddRazorComponents()\n"
                "    .AddInteractiveServerComponents()\n"
                "    .AddInteractiveWebAssemblyComponents();\n"
                "app.MapRazorComponents<App>()\n"
                "    .AddInteractiveServerRenderMode()\n"
                "    .AddInteractiveWebAssemblyRenderMode();\n",
            )
            write(
                root / "App" / "Pages" / "Admin.razor",
                "@rendermode @(new InteractiveServerRenderMode(prerender: false))\n",
            )
            write(
                root / "App.Client" / "App.Client.csproj",
                '<Project Sdk="Microsoft.NET.Sdk.BlazorWebAssembly"><PropertyGroup>'
                "<TargetFramework>net10.0</TargetFramework>"
                "</PropertyGroup></Project>",
            )
            write(
                root / "App.Client" / "Pages" / "Counter.razor",
                "@rendermode InteractiveAuto\n",
            )
            write(
                root / "App.Tests" / "App.Tests.csproj",
                '<Project Sdk="Microsoft.NET.Sdk"><PropertyGroup>'
                "<TargetFramework>net10.0</TargetFramework>"
                "</PropertyGroup><ItemGroup>"
                '<PackageReference Include="xunit" />'
                '<PackageReference Include="FluentAssertions" />'
                "</ItemGroup></Project>",
            )
            data = run_context(root)

            self.assertEqual(
                "Microsoft.Testing.Platform",
                data["test_runner"]["global_json_runner"],
            )
            self.assertTrue(data["central_package_management"]["enabled"])

            blazor = data["blazor"]
            self.assertEqual("blazor-web-app", blazor["hosting_model"])
            self.assertEqual("per-component", blazor["render_mode_scope"])
            self.assertEqual(
                ["InteractiveAuto", "InteractiveServer"],
                blazor["declared_render_modes"],
            )
            self.assertEqual(1, blazor["prerender_disabled_sites"])

            kinds = {
                project["path"]: project["sdk_kind"] for project in data["projects"]
            }
            self.assertEqual(
                "blazor-webassembly",
                kinds[str(Path("App.Client") / "App.Client.csproj")],
            )

            # The licensing flag must survive resolution through central versions.
            tests = next(p for p in data["projects"] if p["is_test_project"])
            self.assertEqual(
                [{"name": "FluentAssertions", "version": "8.2.0"}],
                tests["watched_packages"],
            )


class InventoryEdgeCaseTests(unittest.TestCase):
    """Cases the first review found asserted in prose but never exercised."""

    def test_inherited_directory_build_props_values_are_applied(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            write(
                root / "Directory.Build.props",
                "<Project><PropertyGroup>"
                "<TargetFramework>net10.0</TargetFramework>"
                "<Nullable>enable</Nullable>"
                "</PropertyGroup></Project>",
            )
            write(
                root / "Api" / "Api.csproj",
                f"<Project {WEB_SDK}></Project>",
            )
            project = run_context(root)["projects"][0]

            self.assertEqual(["net10.0"], project["target_frameworks"])
            self.assertEqual("enable", project["properties"]["Nullable"])
            self.assertIn("Nullable", project["inherited_property_names"])

    def test_project_local_property_overrides_inherited(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            write(
                root / "Directory.Build.props",
                "<Project><PropertyGroup>"
                "<TargetFramework>net8.0</TargetFramework>"
                "</PropertyGroup></Project>",
            )
            write(
                root / "Api" / "Api.csproj",
                f"<Project {WEB_SDK}><PropertyGroup>"
                "<TargetFramework>net10.0</TargetFramework>"
                "</PropertyGroup></Project>",
            )
            project = run_context(root)["projects"][0]

            self.assertEqual(["net10.0"], project["target_frameworks"])
            self.assertNotIn("TargetFramework", project["inherited_property_names"])

    def test_nearest_directory_packages_props_wins(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            for where, version in (("", "1.0.0"), ("nested", "2.0.0")):
                write(
                    root / where / "Directory.Packages.props",
                    "<Project><PropertyGroup>"
                    "<ManagePackageVersionsCentrally>true"
                    "</ManagePackageVersionsCentrally>"
                    "</PropertyGroup><ItemGroup>"
                    f'<PackageVersion Include="Serilog" Version="{version}" />'
                    "</ItemGroup></Project>",
                )
            write(
                root / "nested" / "Api" / "Api.csproj",
                f"<Project {WEB_SDK}><PropertyGroup>"
                "<TargetFramework>net10.0</TargetFramework>"
                "</PropertyGroup><ItemGroup>"
                '<PackageReference Include="Serilog" />'
                "</ItemGroup></Project>",
            )
            project = run_context(root)["projects"][0]

            self.assertEqual("2.0.0", project["packages"][0]["version"])

    def test_package_id_match_is_case_insensitive(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            write(
                root / "Directory.Packages.props",
                "<Project><PropertyGroup>"
                "<ManagePackageVersionsCentrally>true</ManagePackageVersionsCentrally>"
                "</PropertyGroup><ItemGroup>"
                '<PackageVersion Include="serilog" Version="4.2.0" />'
                "</ItemGroup></Project>",
            )
            write(
                root / "Api" / "Api.csproj",
                f"<Project {WEB_SDK}><PropertyGroup>"
                "<TargetFramework>net10.0</TargetFramework>"
                "</PropertyGroup><ItemGroup>"
                '<PackageReference Include="Serilog" />'
                "</ItemGroup></Project>",
            )
            package = run_context(root)["projects"][0]["packages"][0]

            self.assertEqual("4.2.0", package["version"])
            self.assertEqual("central", package["source"])

    def test_testing_platform_package_conflicts_with_global_json_default(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            write(
                root / "T" / "T.csproj",
                '<Project Sdk="Microsoft.NET.Sdk"><PropertyGroup>'
                "<TargetFramework>net10.0</TargetFramework>"
                "</PropertyGroup><ItemGroup>"
                '<PackageReference Include="TUnit" Version="0.30.0" />'
                "</ItemGroup></Project>",
            )
            runner = run_context(root)["test_runner"]

            self.assertEqual("VSTest", runner["global_json_runner"])
            self.assertEqual("conflicting", runner["confidence"])
            self.assertTrue(runner["testing_platform_evidence"])

    def test_testing_platform_msbuild_property_is_evidence(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            write(
                root / "T" / "T.csproj",
                '<Project Sdk="Microsoft.NET.Sdk"><PropertyGroup>'
                "<TargetFramework>net10.0</TargetFramework>"
                "<UseMicrosoftTestingPlatformRunner>true"
                "</UseMicrosoftTestingPlatformRunner>"
                "</PropertyGroup></Project>",
            )
            runner = run_context(root)["test_runner"]

            self.assertEqual("conflicting", runner["confidence"])

    def test_commented_out_registration_is_not_treated_as_blazor(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            write(
                root / "Api" / "Api.csproj",
                f"<Project {WEB_SDK}><PropertyGroup>"
                "<TargetFramework>net10.0</TargetFramework>"
                "</PropertyGroup></Project>",
            )
            write(
                root / "Api" / "Program.cs",
                "// builder.Services.AddRazorComponents();\n"
                "/* app.MapRazorComponents<App>(); */\n"
                'app.MapGet("/", () => "ok");\n',
            )
            blazor = run_context(root)["blazor"]

            self.assertIsNone(blazor["hosting_model"])

    def test_malformed_global_json_shapes_do_not_crash(self) -> None:
        for payload in ('{"test": "MTP"}', "[]", "{", '{"test": null}'):
            with (
                self.subTest(payload=payload),
                tempfile.TemporaryDirectory() as temporary,
            ):
                root = Path(temporary)
                write(root / "global.json", payload)
                write(
                    root / "T" / "T.csproj",
                    '<Project Sdk="Microsoft.NET.Sdk"><PropertyGroup>'
                    "<TargetFramework>net10.0</TargetFramework>"
                    "</PropertyGroup></Project>",
                )
                runner = run_context(root)["test_runner"]

                self.assertEqual("VSTest", runner["global_json_runner"])

    def test_malformed_project_xml_is_reported_not_fatal(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            write(root / "Bad" / "Bad.csproj", "<Project><unclosed>")
            write(
                root / "Good" / "Good.csproj",
                f"<Project {WEB_SDK}><PropertyGroup>"
                "<TargetFramework>net10.0</TargetFramework>"
                "</PropertyGroup></Project>",
            )
            projects = run_context(root)["projects"]

            self.assertTrue(any(p.get("unreadable") for p in projects))
            self.assertTrue(any(p.get("sdk_kind") == "web" for p in projects))

    def test_nonexistent_path_fails_instead_of_scanning_parent(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            missing = Path(temporary) / "does-not-exist"
            result = subprocess.run(
                ["python3", "-P", str(CONTEXT), str(missing), "--json"],
                check=False,
                capture_output=True,
                text=True,
            )

            self.assertEqual(2, result.returncode)
            self.assertIn("not a directory", result.stderr)

    def test_project_file_argument_scans_its_directory(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            project = root / "Api" / "Api.csproj"
            write(
                project,
                f"<Project {WEB_SDK}><PropertyGroup>"
                "<TargetFramework>net10.0</TargetFramework>"
                "</PropertyGroup></Project>",
            )
            result = subprocess.run(
                ["python3", "-P", str(CONTEXT), str(project), "--json"],
                check=False,
                capture_output=True,
                text=True,
            )

            self.assertEqual(0, result.returncode, result.stderr)
            self.assertEqual(1, len(json.loads(result.stdout)["projects"]))


if __name__ == "__main__":
    unittest.main()
