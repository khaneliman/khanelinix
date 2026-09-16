from __future__ import annotations

import json
import os
import subprocess
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(__file__).parents[1] / "scripts" / "option-forensics.sh"


class OptionForensicsTest(unittest.TestCase):
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
        self.assertIn("Usage: option-forensics.sh", result.stdout)

    def test_missing_arguments_exits_2(self) -> None:
        result = self.run_script([])
        self.assertEqual(result.returncode, 2)
        self.assertIn("Usage: option-forensics.sh", result.stderr)

        result_one = self.run_script([".#config"])
        self.assertEqual(result_one.returncode, 2)

    def test_unknown_option_exits_2(self) -> None:
        result = self.run_script(["--unknown", ".#config", "opt.path"])
        self.assertEqual(result.returncode, 2)
        self.assertIn("error: unknown option", result.stderr)

    def test_invalid_limit_exits_2(self) -> None:
        result = self.run_script(["--limit", "abc", ".#config", "opt.path"])
        self.assertEqual(result.returncode, 2)
        self.assertIn("error: --limit must be a non-negative integer", result.stderr)

        result_missing = self.run_script(["--limit"])
        self.assertEqual(result_missing.returncode, 2)
        self.assertIn("error: --limit needs a value", result_missing.stderr)

    def test_empty_segment_exits_2(self) -> None:
        result = self.run_script([".#config", "services..enable"])
        self.assertEqual(result.returncode, 2)
        self.assertIn("error: empty segment in option path", result.stderr)

    def test_eval_failure_exits_3(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            stub = Path(tmp) / "nix"
            stub.write_text("#!/bin/sh\necho 'eval failed' >&2\nexit 1\n")
            stub.chmod(0o755)

            result = self.run_script(
                [".#config", "services.openssh.enable"],
                env={"PATH": f"{tmp}:{os.environ.get('PATH', '')}"},
            )
            self.assertEqual(result.returncode, 3)
            self.assertIn(
                "error: evaluation failed; the option path may not exist", result.stderr
            )

    def test_successful_eval_formats_output(self) -> None:
        sample_output = {
            "isDefined": True,
            "highestPrio": 100,
            "type": "boolean",
            "files": [
                "/nix/store/11111111111111111111111111111111-source/modules/ssh.nix",
                "/nix/store/22222222222222222222222222222222-source/modules/base.nix",
            ],
            "definitions": [],
        }

        with tempfile.TemporaryDirectory() as tmp:
            stub = Path(tmp) / "nix"
            stub.write_text(
                f"#!/bin/sh\ncat <<'EOF'\n{json.dumps(sample_output)}\nEOF\n"
            )
            stub.chmod(0o755)

            result = self.run_script(
                [".#config", "services.openssh.enable"],
                env={"PATH": f"{tmp}:{os.environ.get('PATH', '')}"},
            )
            self.assertEqual(result.returncode, 0)
            self.assertIn("option:      services.openssh.enable", result.stdout)
            self.assertIn("type:        boolean", result.stdout)
            self.assertIn("defined:     true", result.stdout)
            self.assertIn("priority:    100 (plain assignment)", result.stdout)
            self.assertIn("files:       2 distinct", result.stdout)
            self.assertIn("modules/ssh.nix", result.stdout)
            self.assertIn("modules/base.nix", result.stdout)

    def test_raw_json_output(self) -> None:
        sample_output = {
            "isDefined": False,
            "highestPrio": None,
            "type": "string",
            "files": [],
            "definitions": [],
        }

        with tempfile.TemporaryDirectory() as tmp:
            stub = Path(tmp) / "nix"
            stub.write_text(
                f"#!/bin/sh\ncat <<'EOF'\n{json.dumps(sample_output)}\nEOF\n"
            )
            stub.chmod(0o755)

            result = self.run_script(
                ["--raw", ".#config", "programs.bash.enable"],
                env={"PATH": f"{tmp}:{os.environ.get('PATH', '')}"},
            )
            self.assertEqual(result.returncode, 0)
            data = json.loads(result.stdout)
            self.assertEqual(data["type"], "string")
            self.assertFalse(data["isDefined"])

    def test_values_and_limit_truncation(self) -> None:
        sample_output = {
            "isDefined": True,
            "highestPrio": 50,
            "type": "list of strings",
            "files": [
                f"/nix/store/11111111111111111111111111111111-source/file{i}.nix"
                for i in range(5)
            ],
            "definitions": [
                {
                    "file": f"/nix/store/11111111111111111111111111111111-source/file{i}.nix",
                    "value": f"value-{i}",
                }
                for i in range(5)
            ],
        }

        with tempfile.TemporaryDirectory() as tmp:
            stub = Path(tmp) / "nix"
            stub.write_text(
                f"#!/bin/sh\ncat <<'EOF'\n{json.dumps(sample_output)}\nEOF\n"
            )
            stub.chmod(0o755)

            result = self.run_script(
                ["--values", "--limit", "2", ".#config", "boot.kernelModules"],
                env={"PATH": f"{tmp}:{os.environ.get('PATH', '')}"},
            )
            self.assertEqual(result.returncode, 0)
            self.assertIn("priority:    50 (mkForce)", result.stdout)
            self.assertIn("files:       5 distinct", result.stdout)
            self.assertIn("... 3 more (raise --limit)", result.stdout)
            self.assertIn("definitions:", result.stdout)
            self.assertIn("value-0", result.stdout)
            self.assertIn("value-1", result.stdout)
            self.assertNotIn("value-2", result.stdout)

    def test_priority_tier_labels(self) -> None:
        tiers = [
            (None, "none"),
            (9999, "9999 (no definitions at all)"),
            (1500, "1500 (mkOptionDefault, i.e. the option default)"),
            (1000, "1000 (mkDefault)"),
            (100, "100 (plain assignment)"),
            (60, "60 (mkImageMediaOverride)"),
            (50, "50 (mkForce)"),
            (10, "10 (mkVMOverride or stronger)"),
        ]

        for prio, expected_label in tiers:
            sample = {
                "isDefined": prio is not None and prio < 9999,
                "highestPrio": prio,
                "type": "boolean",
                "files": [],
                "definitions": [],
            }
            with tempfile.TemporaryDirectory() as tmp:
                stub = Path(tmp) / "nix"
                stub.write_text(f"#!/bin/sh\ncat <<'EOF'\n{json.dumps(sample)}\nEOF\n")
                stub.chmod(0o755)

                result = self.run_script(
                    [".#config", "opt.path"],
                    env={"PATH": f"{tmp}:{os.environ.get('PATH', '')}"},
                )
                self.assertEqual(result.returncode, 0)
                self.assertIn(f"priority:    {expected_label}", result.stdout)


if __name__ == "__main__":
    unittest.main()
