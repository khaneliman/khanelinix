from __future__ import annotations

import json
import os
import subprocess
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(__file__).parents[1] / "scripts" / "option-tree.sh"


SAMPLE_OPTIONS = [
    {
        "path": "services.openssh.enable",
        "type": "boolean",
        "defined": True,
        "prio": 100,
    },
    {
        "path": "services.openssh.port",
        "type": "signed integer",
        "defined": True,
        "prio": 1000,
    },
    {
        "path": "services.openssh.settings",
        "type": "attribute set of unspecified",
        "defined": False,
        "prio": 1500,
    },
    {
        "path": "services.openssh.banner",
        "type": "null or string",
        "defined": False,
        "prio": None,
    },
]


class OptionTreeTest(unittest.TestCase):
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
        self.assertIn("Usage: option-tree.sh", result.stdout)

    def test_missing_arguments_exits_2(self) -> None:
        result = self.run_script([])
        self.assertEqual(result.returncode, 2)
        self.assertIn("Usage: option-tree.sh", result.stderr)

    def test_too_many_arguments_exits_2(self) -> None:
        result = self.run_script([".#config", "prefix", "extra"])
        self.assertEqual(result.returncode, 2)
        self.assertIn("Usage: option-tree.sh", result.stderr)

    def test_mutually_exclusive_filters_exits_2(self) -> None:
        result = self.run_script(["--set-only", "--unset-only", ".#config"])
        self.assertEqual(result.returncode, 2)
        self.assertIn(
            "error: --set-only and --unset-only are mutually exclusive", result.stderr
        )

    def test_invalid_depth_and_limit_exits_2(self) -> None:
        res_depth = self.run_script(["--depth", "abc", ".#config"])
        self.assertEqual(res_depth.returncode, 2)
        self.assertIn("error: --depth must be a non-negative integer", res_depth.stderr)

        res_limit = self.run_script(["--limit", "xyz", ".#config"])
        self.assertEqual(res_limit.returncode, 2)
        self.assertIn("error: --limit must be a non-negative integer", res_limit.stderr)

    def test_empty_segment_in_prefix_exits_2(self) -> None:
        result = self.run_script([".#config", "services..openssh"])
        self.assertEqual(result.returncode, 2)
        self.assertIn("error: empty segment in option path", result.stderr)

    def test_eval_failure_exits_3(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            stub = Path(tmp) / "nix"
            stub.write_text("#!/bin/sh\necho 'eval failed' >&2\nexit 1\n")
            stub.chmod(0o755)

            result = self.run_script(
                [".#config", "services.openssh"],
                env={"PATH": f"{tmp}:{os.environ.get('PATH', '')}"},
            )
            self.assertEqual(result.returncode, 3)
            self.assertIn(
                "error: evaluation failed; the option path may not exist", result.stderr
            )

    def test_successful_tree_formatting_with_prefix(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            stub = Path(tmp) / "nix"
            stub.write_text(
                f"#!/bin/sh\ncat <<'EOF'\n{json.dumps(SAMPLE_OPTIONS)}\nEOF\n"
            )
            stub.chmod(0o755)

            result = self.run_script(
                [".#config", "services.openssh"],
                env={"PATH": f"{tmp}:{os.environ.get('PATH', '')}"},
            )
            self.assertEqual(result.returncode, 0)
            self.assertIn("prefix: services.openssh", result.stdout)
            self.assertIn("options: 4", result.stdout)
            self.assertIn(
                "set           services.openssh.enable  [boolean]", result.stdout
            )
            self.assertIn(
                "mkDefault     services.openssh.port  [signed integer]", result.stdout
            )
            self.assertIn(
                "default       services.openssh.settings  [attribute set of unspecified]",
                result.stdout,
            )
            self.assertIn(
                "unset         services.openssh.banner  [null or string]", result.stdout
            )

    def test_whole_tree_prefix_when_omitted(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            stub = Path(tmp) / "nix"
            stub.write_text(
                f"#!/bin/sh\ncat <<'EOF'\n{json.dumps(SAMPLE_OPTIONS)}\nEOF\n"
            )
            stub.chmod(0o755)

            result = self.run_script(
                [".#config"],
                env={"PATH": f"{tmp}:{os.environ.get('PATH', '')}"},
            )
            self.assertEqual(result.returncode, 0)
            self.assertIn("prefix: (whole tree)", result.stdout)

    def test_set_only_filter(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            stub = Path(tmp) / "nix"
            stub.write_text(
                f"#!/bin/sh\ncat <<'EOF'\n{json.dumps(SAMPLE_OPTIONS)}\nEOF\n"
            )
            stub.chmod(0o755)

            result = self.run_script(
                ["--set-only", ".#config"],
                env={"PATH": f"{tmp}:{os.environ.get('PATH', '')}"},
            )
            self.assertEqual(result.returncode, 0)
            self.assertIn("options: 2", result.stdout)
            self.assertIn("services.openssh.enable", result.stdout)
            self.assertIn("services.openssh.port", result.stdout)
            self.assertNotIn("services.openssh.settings", result.stdout)
            self.assertNotIn("services.openssh.banner", result.stdout)

    def test_unset_only_filter(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            stub = Path(tmp) / "nix"
            stub.write_text(
                f"#!/bin/sh\ncat <<'EOF'\n{json.dumps(SAMPLE_OPTIONS)}\nEOF\n"
            )
            stub.chmod(0o755)

            result = self.run_script(
                ["--unset-only", ".#config"],
                env={"PATH": f"{tmp}:{os.environ.get('PATH', '')}"},
            )
            self.assertEqual(result.returncode, 0)
            self.assertIn("options: 2", result.stdout)
            self.assertNotIn("services.openssh.enable", result.stdout)
            self.assertIn("services.openssh.settings", result.stdout)
            self.assertIn("services.openssh.banner", result.stdout)

    def test_limit_truncation(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            stub = Path(tmp) / "nix"
            stub.write_text(
                f"#!/bin/sh\ncat <<'EOF'\n{json.dumps(SAMPLE_OPTIONS)}\nEOF\n"
            )
            stub.chmod(0o755)

            result = self.run_script(
                ["--limit", "2", ".#config"],
                env={"PATH": f"{tmp}:{os.environ.get('PATH', '')}"},
            )
            self.assertEqual(result.returncode, 0)
            self.assertIn("... 2 more (raise --limit)", result.stdout)

    def test_raw_json_output(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            stub = Path(tmp) / "nix"
            stub.write_text(
                f"#!/bin/sh\ncat <<'EOF'\n{json.dumps(SAMPLE_OPTIONS)}\nEOF\n"
            )
            stub.chmod(0o755)

            result = self.run_script(
                ["--raw", ".#config"],
                env={"PATH": f"{tmp}:{os.environ.get('PATH', '')}"},
            )
            self.assertEqual(result.returncode, 0)
            data = json.loads(result.stdout)
            self.assertEqual(len(data), 4)
            self.assertEqual(data[0]["path"], "services.openssh.enable")


if __name__ == "__main__":
    unittest.main()
