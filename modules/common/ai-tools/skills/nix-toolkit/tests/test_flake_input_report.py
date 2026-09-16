from __future__ import annotations

import importlib.util
import io
import json
import subprocess
import sys
import unittest
from pathlib import Path
from unittest.mock import patch

SCRIPT = Path(__file__).parents[1] / "scripts" / "flake_input_report.py"
SPEC = importlib.util.spec_from_file_location("flake_input_report", SCRIPT)
assert SPEC is not None and SPEC.loader is not None
flake_input_report = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = flake_input_report
SPEC.loader.exec_module(flake_input_report)


SAMPLE_METADATA = {
    "locks": {
        "root": "root",
        "nodes": {
            "root": {
                "inputs": {
                    "nixpkgs": "nixpkgs",
                    "home-manager": "home-manager",
                }
            },
            "nixpkgs": {
                "locked": {
                    "type": "github",
                    "owner": "NixOS",
                    "repo": "nixpkgs",
                    "rev": "abcdef1234567890abcdef1234567890abcdef12",
                    "lastModified": 1700000000,
                }
            },
            "home-manager": {
                "inputs": {
                    # List target: a `follows` redirected to the root's nixpkgs.
                    "nixpkgs": ["nixpkgs"],
                    # String target: a direct reference to its own node.
                    "utils": "local-tool",
                },
                "locked": {
                    "type": "github",
                    "owner": "nix-community",
                    "repo": "home-manager",
                    "rev": "9999999999999999999999999999999999999999",
                    "lastModified": 1600000000,
                },
            },
            "local-tool": {
                "locked": {
                    "type": "path",
                    "path": "/home/user/src/tool",
                    "narHash": "sha256-abc",
                }
            },
        },
    }
}


class InputAgeTest(unittest.TestCase):
    def test_age_days_none_when_last_modified_missing(self) -> None:
        item = flake_input_report.Input(name="pkg", reference="github:org/repo")
        self.assertIsNone(item.age_days(1700000000))

    def test_age_days_calculation(self) -> None:
        now = 1700000000
        item = flake_input_report.Input(
            name="pkg", reference="github:org/repo", last_modified=now - 86400 * 10
        )
        self.assertEqual(item.age_days(now), 10)

    def test_age_days_clamps_negative_to_zero(self) -> None:
        now = 1700000000
        item = flake_input_report.Input(
            name="pkg", reference="github:org/repo", last_modified=now + 500
        )
        self.assertEqual(item.age_days(now), 0)


class DescribeTest(unittest.TestCase):
    def test_describe_github_without_ref(self) -> None:
        locked = {"type": "github", "owner": "NixOS", "repo": "nixpkgs"}
        self.assertEqual(flake_input_report.describe(locked), "github:NixOS/nixpkgs")

    def test_describe_github_with_ref(self) -> None:
        locked = {
            "type": "github",
            "owner": "NixOS",
            "repo": "nixpkgs",
            "ref": "nixos-unstable",
        }
        self.assertEqual(
            flake_input_report.describe(locked), "github:NixOS/nixpkgs#nixos-unstable"
        )

    def test_describe_gitlab(self) -> None:
        locked = {"type": "gitlab", "owner": "gnome", "repo": "shell", "ref": "main"}
        self.assertEqual(flake_input_report.describe(locked), "gitlab:gnome/shell#main")

    def test_describe_path(self) -> None:
        locked = {"type": "path", "path": "/srv/repo"}
        self.assertEqual(flake_input_report.describe(locked), "path:/srv/repo")

    def test_describe_tarball_with_url(self) -> None:
        locked = {"type": "tarball", "url": "https://example.com/archive.tar.gz"}
        self.assertEqual(
            flake_input_report.describe(locked), "https://example.com/archive.tar.gz"
        )

    def test_describe_unknown_type(self) -> None:
        locked = {"type": "custom-vcs"}
        self.assertEqual(flake_input_report.describe(locked), "custom-vcs")


class CollectInputsTest(unittest.TestCase):
    def test_collects_and_sorts_inputs(self) -> None:
        inputs = flake_input_report.collect_inputs(SAMPLE_METADATA)
        names = [item.name for item in inputs]
        self.assertEqual(names, ["home-manager", "local-tool", "nixpkgs"])

        hm = inputs[0]
        self.assertEqual(hm.reference, "github:nix-community/home-manager")
        self.assertEqual(hm.revision, "9999999999999999999999999999999999999999")
        self.assertEqual(hm.last_modified, 1600000000)
        self.assertEqual(hm.follows, ["nixpkgs -> nixpkgs"])

        local = inputs[1]
        self.assertEqual(local.reference, "path:/home/user/src/tool")
        self.assertEqual(local.revision, "sha256-abc")
        self.assertIsNone(local.last_modified)
        # String edge: home-manager references this node directly.
        self.assertEqual(local.followed_by, ["home-manager"])

        nixpkgs = inputs[2]
        # A `follows` edge does not pin the target; only a direct reference does.
        self.assertEqual(nixpkgs.followed_by, [])
        self.assertEqual(nixpkgs.follows, [])

    def test_handles_empty_locks(self) -> None:
        self.assertEqual(flake_input_report.collect_inputs({}), [])
        self.assertEqual(
            flake_input_report.collect_inputs({"locks": {"root": "root", "nodes": {}}}),
            [],
        )


class BuildAndFormatReportTest(unittest.TestCase):
    inputs: list[flake_input_report.Input]

    def setUp(self) -> None:
        self.inputs = flake_input_report.collect_inputs(SAMPLE_METADATA)

    def test_build_report_identifies_stale_inputs(self) -> None:
        report = flake_input_report.build_report(self.inputs, stale_days=90)
        self.assertEqual(report["inputCount"], 3)
        self.assertEqual(report["staleThresholdDays"], 90)
        self.assertIn("home-manager", report["staleInputs"])
        self.assertNotIn("local-tool", report["staleInputs"])

    def test_format_report_includes_metadata_and_markers(self) -> None:
        report = flake_input_report.build_report(self.inputs, stale_days=90)
        output = flake_input_report.format_report(report, limit=40)
        self.assertIn("inputs:  3", output)
        self.assertIn("home-manager *", output)
        self.assertIn("follows nixpkgs -> nixpkgs", output)
        self.assertIn("pinned by home-manager", output)
        self.assertIn("* stale. Age is the lock's lastModified", output)

    def test_format_report_limit_truncation(self) -> None:
        report = flake_input_report.build_report(self.inputs, stale_days=90)
        output = flake_input_report.format_report(report, limit=1)
        self.assertIn("... 2 more (raise --limit)", output)

    def test_format_report_no_stale_footnote_when_none_stale(self) -> None:
        report = flake_input_report.build_report(self.inputs, stale_days=999999)
        output = flake_input_report.format_report(report, limit=40)
        self.assertNotIn("* stale.", output)


class ReadMetadataTest(unittest.TestCase):
    def test_successful_read(self) -> None:
        with patch("subprocess.run") as mock_run:
            mock_run.return_value = subprocess.CompletedProcess(
                args=[], returncode=0, stdout=json.dumps(SAMPLE_METADATA), stderr=""
            )
            data = flake_input_report.read_metadata(".")
            self.assertEqual(data["locks"]["root"], "root")

    def test_read_failure_raises(self) -> None:
        with (
            patch("subprocess.run") as mock_run,
            patch("sys.stderr", new_callable=io.StringIO),
        ):
            mock_run.return_value = subprocess.CompletedProcess(
                args=[], returncode=1, stdout="", stderr="error: not a flake"
            )
            with self.assertRaisesRegex(
                flake_input_report.FlakeInputError, "could not read flake metadata"
            ):
                flake_input_report.read_metadata("/invalid")

    def test_command_not_found_raises(self) -> None:
        with (
            patch("subprocess.run", side_effect=FileNotFoundError("nix not found")),
            self.assertRaisesRegex(
                flake_input_report.FlakeInputError, "could not run nix"
            ),
        ):
            flake_input_report.read_metadata(".")


class MainCliTest(unittest.TestCase):
    def test_main_text_output_exit_0(self) -> None:
        with (
            patch.object(
                flake_input_report, "read_metadata", return_value=SAMPLE_METADATA
            ),
            patch("sys.stdout", new_callable=io.StringIO) as mock_out,
        ):
            code = flake_input_report.main([])
            self.assertEqual(code, 0)
            self.assertIn("inputs:  3", mock_out.getvalue())

    def test_main_json_output_exit_0(self) -> None:
        with (
            patch.object(
                flake_input_report, "read_metadata", return_value=SAMPLE_METADATA
            ),
            patch("sys.stdout", new_callable=io.StringIO) as mock_out,
        ):
            code = flake_input_report.main(["--json"])
            self.assertEqual(code, 0)
            data = json.loads(mock_out.getvalue())
            self.assertEqual(data["inputCount"], 3)

    def test_main_metadata_error_exit_3(self) -> None:
        with (
            patch.object(
                flake_input_report,
                "read_metadata",
                side_effect=flake_input_report.FlakeInputError("fail"),
            ),
            patch("sys.stderr", new_callable=io.StringIO) as mock_err,
        ):
            code = flake_input_report.main(["bad-flake"])
            self.assertEqual(code, 3)
            self.assertIn("error: fail", mock_err.getvalue())


if __name__ == "__main__":
    unittest.main()
