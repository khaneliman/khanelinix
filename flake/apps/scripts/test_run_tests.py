import contextlib
import io
import subprocess
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

import run_tests

ROOT = Path(__file__).resolve().parents[3]
SOURCES = {
    "nixpkgs": "/nix/store/locked-nixpkgs",
    "home-manager": "/nix/store/locked-home-manager",
    "niri": "/nix/store/locked-niri",
}


class RunTests(unittest.TestCase):
    def test_list_does_not_resolve_inputs(self):
        with (
            patch.object(run_tests, "locked_sources") as locked_sources,
            contextlib.redirect_stdout(io.StringIO()) as output,
        ):
            self.assertEqual(run_tests.main(["--list"]), 0)
        locked_sources.assert_not_called()
        self.assertEqual(output.getvalue().splitlines(), list(run_tests.CHECKS))

    def test_default_runs_focused_checks_and_reports_failures(self):
        with (
            tempfile.TemporaryDirectory() as scratch,
            patch.object(run_tests.platform, "system", return_value="Linux"),
            patch.object(run_tests, "locked_sources", return_value=SOURCES) as resolve,
            patch.object(run_tests, "run_check") as run,
            contextlib.redirect_stdout(io.StringIO()) as output,
            contextlib.redirect_stderr(io.StringIO()),
        ):
            run.side_effect = [subprocess.CalledProcessError(11, ["test"])] + [None] * (
                len(run_tests.CHECKS) - 1
            )
            result = run_tests.main(["--root", str(ROOT), "--scratch", scratch])

        self.assertEqual(result, 1)
        resolve.assert_called_once_with(ROOT)
        support = (
            (ROOT / "docs/support.md")
            .read_text()
            .split("## Focused regression checks")[1]
        )
        documented = {
            line.split("tests/")[1].split(".py")[0]
            for line in support.splitlines()
            if "python3 " in line and "tests/" in line
        }
        self.assertEqual({call.args[0] for call in run.call_args_list}, documented)
        self.assertEqual(len(run.call_args_list), len(documented))
        self.assertIn("Failed checks: module-regressions", output.getvalue())

    def test_package_runtime_uses_pinned_tools_and_scratch_cwd(self):
        with (
            tempfile.TemporaryDirectory() as parent,
            patch.object(run_tests.subprocess, "run") as run,
            contextlib.redirect_stdout(io.StringIO()),
        ):
            name = "package-runtime-regressions"
            scratch = Path(parent) / name
            run_tests.run_check(name, run_tests.CHECKS[name], ROOT, scratch, SOURCES)

        command = run.call_args.args[0]
        self.assertEqual(command[:3], ["nix", "shell", "--no-write-lock-file"])
        args = command.index("--command")
        for tool in command[3:args]:
            self.assertTrue(tool.startswith(f"path:{SOURCES['nixpkgs']}#"))
        self.assertEqual(
            command[-2:], [str(ROOT / "tests" / f"{name}.py"), SOURCES["nixpkgs"]]
        )
        self.assertEqual(run.call_args.kwargs["cwd"], scratch)
        self.assertEqual(run.call_args.kwargs["env"]["TMPDIR"], str(scratch))


if __name__ == "__main__":
    unittest.main()
