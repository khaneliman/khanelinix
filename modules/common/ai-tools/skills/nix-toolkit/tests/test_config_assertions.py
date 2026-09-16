from __future__ import annotations

import json
import os
import subprocess
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(__file__).parents[1] / "scripts" / "config-assertions.sh"


class ConfigAssertionsTest(unittest.TestCase):
    def run_script(
        self,
        args: list[str],
        env: dict[str, str] | None = None,
    ) -> subprocess.CompletedProcess[str]:
        full_env = os.environ.copy()
        if env:
            full_env.update(env)
        return subprocess.run(
            ["bash", str(SCRIPT), *args],
            capture_output=True,
            text=True,
            env=full_env,
            check=False,
        )

    def test_help_flag_exits_0(self) -> None:
        result = self.run_script(["--help"])
        self.assertEqual(result.returncode, 0)
        self.assertIn("Usage: config-assertions.sh", result.stdout)

    def test_missing_arguments_exits_2(self) -> None:
        result = self.run_script([])
        self.assertEqual(result.returncode, 2)
        self.assertIn("Usage: config-assertions.sh", result.stderr)

    def test_unexpected_argument_exits_2(self) -> None:
        result = self.run_script([".#config", "extra_arg"])
        self.assertEqual(result.returncode, 2)
        self.assertIn("error: unexpected argument", result.stderr)

    def test_unknown_option_exits_2(self) -> None:
        result = self.run_script(["--unknown", ".#config"])
        self.assertEqual(result.returncode, 2)
        self.assertIn("error: unknown option", result.stderr)

    def test_eval_failure_exits_3(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            stub = Path(tmp) / "nix"
            stub.write_text("#!/bin/sh\necho 'syntax error in config' >&2\nexit 1\n")
            stub.chmod(0o755)

            result = self.run_script(
                [".#config"],
                env={"PATH": f"{tmp}:{os.environ.get('PATH', '')}"},
            )
            self.assertEqual(result.returncode, 3)
            self.assertIn(
                "error: evaluation failed; the configuration may not evaluate at all",
                result.stderr,
            )

    def test_passing_assertions_exits_0(self) -> None:
        sample = {
            "failed": [],
            "passed": 42,
            "warnings": [],
        }
        with tempfile.TemporaryDirectory() as tmp:
            stub = Path(tmp) / "nix"
            stub.write_text(f"#!/bin/sh\ncat <<'EOF'\n{json.dumps(sample)}\nEOF\n")
            stub.chmod(0o755)

            result = self.run_script(
                [".#config"],
                env={"PATH": f"{tmp}:{os.environ.get('PATH', '')}"},
            )
            self.assertEqual(result.returncode, 0)
            self.assertIn("failed assertions: 0", result.stdout)
            self.assertIn("warnings: 0", result.stdout)
            self.assertNotIn("passing assertions:", result.stdout)

    def test_all_flag_shows_passing_count(self) -> None:
        sample = {
            "failed": [],
            "passed": 55,
            "warnings": [],
        }
        with tempfile.TemporaryDirectory() as tmp:
            stub = Path(tmp) / "nix"
            stub.write_text(f"#!/bin/sh\ncat <<'EOF'\n{json.dumps(sample)}\nEOF\n")
            stub.chmod(0o755)

            result = self.run_script(
                ["--all", ".#config"],
                env={"PATH": f"{tmp}:{os.environ.get('PATH', '')}"},
            )
            self.assertEqual(result.returncode, 0)
            self.assertIn("failed assertions: 0", result.stdout)
            self.assertIn("passing assertions: 55", result.stdout)

    def test_failed_assertions_exits_1(self) -> None:
        sample = {
            "failed": ["The option services.openssh.enable requires networking.enable"],
            "passed": 10,
            "warnings": [],
        }
        with tempfile.TemporaryDirectory() as tmp:
            stub = Path(tmp) / "nix"
            stub.write_text(f"#!/bin/sh\ncat <<'EOF'\n{json.dumps(sample)}\nEOF\n")
            stub.chmod(0o755)

            result = self.run_script(
                [".#config"],
                env={"PATH": f"{tmp}:{os.environ.get('PATH', '')}"},
            )
            self.assertEqual(result.returncode, 1)
            self.assertIn("failed assertions: 1", result.stdout)
            self.assertIn(
                "✗ The option services.openssh.enable requires networking.enable",
                result.stdout,
            )

    def test_warnings_do_not_cause_nonzero_exit(self) -> None:
        sample = {
            "failed": [],
            "passed": 20,
            "warnings": ["Deprecated option used\nPlease migrate to newOption"],
        }
        with tempfile.TemporaryDirectory() as tmp:
            stub = Path(tmp) / "nix"
            stub.write_text(f"#!/bin/sh\ncat <<'EOF'\n{json.dumps(sample)}\nEOF\n")
            stub.chmod(0o755)

            result = self.run_script(
                [".#config"],
                env={"PATH": f"{tmp}:{os.environ.get('PATH', '')}"},
            )
            self.assertEqual(result.returncode, 0)
            self.assertIn("warnings: 1", result.stdout)
            self.assertIn(
                "! Deprecated option used\n    Please migrate to newOption",
                result.stdout,
            )

    def test_raw_json_output(self) -> None:
        sample = {
            "failed": ["Assertion failed"],
            "passed": 5,
            "warnings": ["Some warning"],
        }
        with tempfile.TemporaryDirectory() as tmp:
            stub = Path(tmp) / "nix"
            stub.write_text(f"#!/bin/sh\ncat <<'EOF'\n{json.dumps(sample)}\nEOF\n")
            stub.chmod(0o755)

            result = self.run_script(
                ["--raw", ".#config"],
                env={"PATH": f"{tmp}:{os.environ.get('PATH', '')}"},
            )
            self.assertEqual(result.returncode, 1)
            data = json.loads(result.stdout)
            self.assertEqual(data["failed"], ["Assertion failed"])


if __name__ == "__main__":
    unittest.main()
