from __future__ import annotations

import json
import subprocess
import tempfile
import unittest
from pathlib import Path

SKILL = Path(__file__).parents[1]
CONTEXT = SKILL / "scripts" / "project-context.py"
VERIFY = SKILL / "scripts" / "rust-verify.sh"


class RustScriptTests(unittest.TestCase):
    def test_context_does_not_create_lockfile(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            (root / "src").mkdir()
            (root / "Cargo.toml").write_text(
                '[package]\nname = "fixture"\nversion = "0.1.0"\nedition = "2024"\n'
            )
            (root / "src" / "lib.rs").write_text("pub fn value() -> u8 { 1 }\n")

            result = subprocess.run(
                ["python3", str(CONTEXT), str(root), "--json"],
                check=False,
                capture_output=True,
                text=True,
            )
            self.assertEqual(0, result.returncode, result.stderr)
            report = json.loads(result.stdout)
            self.assertEqual("fixture", report["packages"][0]["name"])
            self.assertFalse((root / "Cargo.lock").exists())

    def test_verify_dry_run_is_locked_and_non_mutating(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            manifest = root / "Cargo.toml"
            manifest.write_text(
                '[package]\nname = "fixture"\nversion = "0.1.0"\nedition = "2024"\n'
            )
            result = subprocess.run(
                [
                    "bash",
                    str(VERIFY),
                    "--manifest-path",
                    str(manifest),
                    "--mode",
                    "full",
                    "--dry-run",
                ],
                check=False,
                capture_output=True,
                text=True,
            )
            self.assertEqual(0, result.returncode, result.stderr)
            self.assertIn("cargo check", result.stdout)
            self.assertIn("--locked", result.stdout)
            self.assertIn("cargo clippy", result.stdout)
            self.assertIn("cargo test", result.stdout)
            self.assertFalse((root / "Cargo.lock").exists())

    def test_verify_rejects_conflicting_feature_modes(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            manifest = Path(temporary) / "Cargo.toml"
            manifest.write_text("[workspace]\nmembers = []\n")
            result = subprocess.run(
                [
                    "bash",
                    str(VERIFY),
                    "--manifest-path",
                    str(manifest),
                    "--all-features",
                    "--features",
                    "extra",
                    "--dry-run",
                ],
                check=False,
                capture_output=True,
                text=True,
            )
            self.assertEqual(2, result.returncode)
            self.assertIn("cannot be combined", result.stderr)


if __name__ == "__main__":
    unittest.main()
