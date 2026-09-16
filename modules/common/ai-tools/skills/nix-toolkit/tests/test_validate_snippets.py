from __future__ import annotations

import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(__file__).parents[1] / "scripts" / "validate-snippets.sh"


class ValidateSnippetsTest(unittest.TestCase):
    def setUpFixture(self, root: Path, ref_content: str) -> Path:
        scripts_dir = root / "scripts"
        refs_dir = root / "references"
        scripts_dir.mkdir(parents=True, exist_ok=True)
        refs_dir.mkdir(parents=True, exist_ok=True)

        dest_script = scripts_dir / "validate-snippets.sh"
        shutil.copy(SCRIPT, dest_script)
        dest_script.chmod(0o755)

        (refs_dir / "test.md").write_text(ref_content, encoding="utf-8")
        return dest_script

    def run_fixture(self, script_path: Path) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            ["bash", str(script_path)],
            capture_output=True,
            text=True,
            check=False,
        )

    def test_rejects_boolean_flag_without_option(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            ref = """
# Test Reference
```bash
nix build --allow-import-from-derivation false
```
"""
            script = self.setUpFixture(Path(tmp), ref)
            result = self.run_fixture(script)
            self.assertEqual(result.returncode, 1)
            self.assertIn("boolean flag given a value without --option", result.stderr)

    def test_accepts_boolean_flag_with_option(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            ref = """
# Test Reference
```bash
nix build --option allow-import-from-derivation false
```
```nix
lib.mkIf true {}
```
"""
            script = self.setUpFixture(Path(tmp), ref)
            result = self.run_fixture(script)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn("nix-toolkit snippets validated", result.stdout)

    def test_rejects_nonexistent_lib_attribute(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            ref = """
# Test Reference
```nix
lib.types.isRawType
```
"""
            script = self.setUpFixture(Path(tmp), ref)
            result = self.run_fixture(script)
            self.assertEqual(result.returncode, 1)
            self.assertIn(
                "attribute paths above do not resolve in nixpkgs lib or builtins",
                result.stderr,
            )
            self.assertIn("lib.types.isRawType", result.stderr)

    def test_allows_whitelisted_missing_attribute(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            ref = """
# Test Reference
```nix
builtins.parallel
```
"""
            script = self.setUpFixture(Path(tmp), ref)
            result = self.run_fixture(script)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn("nix-toolkit snippets validated", result.stdout)

    def test_rejects_invalid_bash_syntax_in_snippet(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            ref = """
# Test Reference
```bash
if then fi
```
"""
            script = self.setUpFixture(Path(tmp), ref)
            result = self.run_fixture(script)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("syntax error", result.stderr.lower())


if __name__ == "__main__":
    unittest.main()
