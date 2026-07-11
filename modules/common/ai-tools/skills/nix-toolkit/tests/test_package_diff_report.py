from __future__ import annotations

import importlib.util
import json
import subprocess
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(__file__).parents[1] / "scripts" / "package_diff_report.py"
SPEC = importlib.util.spec_from_file_location("package_diff_report", SCRIPT)
assert SPEC is not None and SPEC.loader is not None
package_diff_report = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(package_diff_report)


def completed(stdout: bytes = b"", stderr: bytes = b"", code: int = 0):
    return subprocess.CompletedProcess([], code, stdout, stderr)


class FakeRunner:
    def __init__(self, before: Path, after: Path) -> None:
        self.before = before
        self.after = after
        self.calls: list[tuple[tuple[str, ...], Path, bool]] = []

    def __call__(self, arguments, cwd: Path, check: bool):
        args = tuple(arguments)
        self.calls.append((args, cwd, check))
        if args[:2] == ("nix", "build"):
            output = self.before if args[-1] == "before#pkg" else self.after
            return completed(f"{output}\n".encode())
        if args[:2] == ("nix", "path-info"):
            output = self.before if str(self.before) in args else self.after
            dependency = (
                "/nix/store/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa-old-dep"
                if output == self.before
                else "/nix/store/bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb-new-dep"
            )
            data = {
                str(output): {"narSize": 10},
                dependency: {"narSize": 5},
            }
            return completed(json.dumps(data).encode())
        if args[0] == "/tools/diffoscope":
            report_path = Path(args[2])
            report_path.write_text(
                "--- /nix/store/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa-old/file\n"
                "+++ /nix/store/bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb-new/file\n",
                encoding="utf-8",
            )
            return completed(code=1)
        raise AssertionError(f"unexpected command: {args}")


class PackageDiffReportTests(unittest.TestCase):
    def test_build_preserves_multi_output_order_when_hash_sort_would_flip(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_root:
            root = Path(temporary_root)
            before_outputs = [root / "z-before-out", root / "a-before-dev"]
            after_outputs = [root / "a-after-out", root / "z-after-dev"]
            for output in [*before_outputs, *after_outputs]:
                output.mkdir()

            def multi_output_runner(arguments, _cwd: Path, _check: bool):
                outputs = (
                    before_outputs if arguments[-1] == "before#pkg" else after_outputs
                )
                return completed(
                    ("\n".join(str(output) for output in outputs) + "\n").encode()
                )

            self.assertEqual(
                package_diff_report.build_installable(
                    multi_output_runner, root, "before#pkg"
                ),
                before_outputs,
            )
            self.assertEqual(
                package_diff_report.build_installable(
                    multi_output_runner, root, "after#pkg"
                ),
                after_outputs,
            )

    def test_report_uses_isolated_build_flags_and_stable_bounded_data(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_root:
            root = Path(temporary_root)
            before = root / "before-output"
            after = root / "after-output"
            before.mkdir()
            after.mkdir()
            (before / "same.txt").write_text("before", encoding="utf-8")
            (after / "same.txt").write_text("after", encoding="utf-8")
            (after / "added.txt").write_text("added", encoding="utf-8")
            fake = FakeRunner(before, after)

            report = package_diff_report.build_report(
                root,
                "before#pkg",
                "after#pkg",
                maximum_items=1,
                runner=fake,
            )

            self.assertEqual(report["files"]["added"]["count"], 1)
            self.assertEqual(report["files"]["changed"]["count"], 1)
            self.assertEqual(report["closure"]["added"]["count"], 2)
            build_commands = [
                args
                for args, _cwd, _check in fake.calls
                if args[:2] == ("nix", "build")
            ]
            self.assertEqual(len(build_commands), 2)
            for command in build_commands:
                self.assertIn("--no-link", command)
                self.assertIn("--no-update-lock-file", command)
                self.assertIn("--no-write-lock-file", command)
                self.assertEqual(command[-2], "--")
                self.assertNotIn("--out-link", command)

    def test_optional_diffoscope_is_bounded_and_normalized(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_root:
            root = Path(temporary_root)
            before = root / "before-output"
            after = root / "after-output"
            before.mkdir()
            after.mkdir()
            fake = FakeRunner(before, after)

            report = package_diff_report.build_report(
                root,
                "before#pkg",
                "after#pkg",
                diffoscope=True,
                diffoscope_lines=1,
                runner=fake,
                which=lambda _name: "/tools/diffoscope",
            )

            comparison = report["diffoscope"]["comparisons"][0]
            self.assertTrue(comparison["different"])
            self.assertEqual(len(comparison["excerpt"]), 1)
            self.assertIn("/nix/store/<hash>-old/file", comparison["excerpt"][0])
            self.assertEqual(comparison["excerpt_lines_omitted"], 1)

    def test_missing_diffoscope_fails_before_external_command(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_root:
            root = Path(temporary_root)
            before = root / "before-output"
            after = root / "after-output"
            before.mkdir()
            after.mkdir()
            fake = FakeRunner(before, after)

            with self.assertRaisesRegex(
                package_diff_report.PackageDiffError, "not on PATH"
            ):
                package_diff_report.build_report(
                    root,
                    "before#pkg",
                    "after#pkg",
                    diffoscope=True,
                    runner=fake,
                    which=lambda _name: None,
                )


if __name__ == "__main__":
    unittest.main()
