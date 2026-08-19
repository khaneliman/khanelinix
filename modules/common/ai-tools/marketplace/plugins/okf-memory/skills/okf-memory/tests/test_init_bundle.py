from __future__ import annotations

import json
import subprocess
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(__file__).parents[1] / "scripts" / "init_bundle.py"


class InitBundleTests(unittest.TestCase):
    def run_script(
        self, *args: str, expected: int = 0
    ) -> subprocess.CompletedProcess[str]:
        result = subprocess.run(
            ["python3", str(SCRIPT), *args],
            check=False,
            capture_output=True,
            text=True,
        )
        self.assertEqual(expected, result.returncode, result.stderr)
        return result

    def test_preview_is_read_only(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            bundle = Path(temporary) / ".okf"
            result = self.run_script("--bundle-dir", str(bundle))
            report = json.loads(result.stdout)
            self.assertEqual("changes_pending", report["status"])
            self.assertFalse(bundle.exists())

    def test_apply_then_noop_preserves_existing_files(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            bundle = root / ".okf"
            gitignore = root / ".gitignore"

            first = self.run_script(
                "--bundle-dir",
                str(bundle),
                "--gitignore",
                str(gitignore),
                "--date",
                "2026-07-28",
                "--apply",
            )
            self.assertEqual("changed", json.loads(first.stdout)["status"])
            self.assertTrue((bundle / "concepts").is_dir())
            self.assertIn("2026-07-28", (bundle / "log.md").read_text())
            self.assertIn(".okf/MEMORY.local.md", gitignore.read_text())

            custom = "custom memory\n"
            (bundle / "MEMORY.local.md").write_text(custom)
            second = self.run_script(
                "--bundle-dir",
                str(bundle),
                "--gitignore",
                str(gitignore),
                "--apply",
            )
            self.assertEqual("noop", json.loads(second.stdout)["status"])
            self.assertEqual(custom, (bundle / "MEMORY.local.md").read_text())

    def test_gitignore_must_own_bundle_path(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            outside = root / "outside" / ".okf"
            project = root / "project"
            project.mkdir()
            result = self.run_script(
                "--bundle-dir",
                str(outside),
                "--gitignore",
                str(project / ".gitignore"),
                expected=2,
            )
            self.assertIn("must be inside", result.stderr)

    def test_symlink_targets_are_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            outside = root / "outside"
            outside.mkdir()

            bundle_link = root / "bundle-link"
            bundle_link.symlink_to(outside, target_is_directory=True)
            bundle_result = self.run_script(
                "--bundle-dir", str(bundle_link), expected=2
            )
            self.assertIn("must not be a symlink", bundle_result.stderr)

            bundle = root / ".okf"
            bundle.mkdir()
            concepts = bundle / "concepts"
            concepts.symlink_to(outside, target_is_directory=True)
            concepts_result = self.run_script("--bundle-dir", str(bundle), expected=2)
            self.assertIn(
                "concepts target must not be a symlink", concepts_result.stderr
            )
            concepts.unlink()

            (bundle / "index.md").symlink_to(outside / "missing-index")
            file_result = self.run_script("--bundle-dir", str(bundle), expected=2)
            self.assertIn(
                "bundle file target must not be a symlink", file_result.stderr
            )
            (bundle / "index.md").unlink()

            gitignore = root / ".gitignore"
            gitignore.symlink_to(outside / "gitignore")
            gitignore_result = self.run_script(
                "--bundle-dir",
                str(bundle),
                "--gitignore",
                str(gitignore),
                expected=2,
            )
            self.assertIn(
                "gitignore target must not be a symlink", gitignore_result.stderr
            )


if __name__ == "__main__":
    unittest.main()
