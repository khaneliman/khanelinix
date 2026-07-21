import os
import subprocess
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(__file__).parents[1] / "scripts" / "codex-lane.sh"


class CodexLaneTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        self.repo = self.root / "repo"
        self.bin = self.root / "bin"
        self.repo.mkdir()
        self.bin.mkdir()
        subprocess.run(["git", "init", "-q", str(self.repo)], check=True)
        subprocess.run(
            ["git", "-C", str(self.repo), "commit", "--allow-empty", "-qm", "base"],
            check=True,
        )
        (self.repo / "plan.md").write_text("# Plan\n", encoding="utf-8")
        fake = self.bin / "codex"
        fake.write_text(
            """#!/usr/bin/env bash
set -euo pipefail
printf '%s\\0' \"$@\" >\"$CODEX_ARGS_FILE\"
prompt=$(cat)
printf '%s' \"$prompt\" >\"$CODEX_PROMPT_FILE\"
sleep \"${FAKE_CODEX_SLEEP:-0}\"
output=
while [[ $# -gt 0 ]]; do
  if [[ $1 == --output-last-message ]]; then
    output=$2
    break
  fi
  shift
done
printf '{}' >\"$output\"
""",
            encoding="utf-8",
        )
        fake.chmod(0o755)
        self.args_file = self.root / "args"
        self.prompt_file = self.root / "prompt"
        self.env = os.environ | {
            "PATH": f"{self.bin}:{os.environ['PATH']}",
            "CODEX_ARGS_FILE": str(self.args_file),
            "CODEX_PROMPT_FILE": str(self.prompt_file),
        }

    def tearDown(self):
        self.temp.cleanup()

    def run_lane(self, *args):
        return subprocess.run(
            ["bash", str(SCRIPT), *args],
            cwd=self.repo,
            env=self.env,
            text=True,
            capture_output=True,
        )

    def captured_args(self):
        return self.args_file.read_bytes().decode().rstrip("\0").split("\0")

    def test_modes_select_expected_profile_and_sandbox(self):
        cases = {
            "spark": ("spark", "read-only"),
            "discover": ("quick", "read-only"),
            "probe": ("quick", "workspace-write"),
            "test": ("quick", "workspace-write"),
            "implement": ("quick", "workspace-write"),
            "code-review": ("deep", "read-only"),
            "debug": ("deep", "read-only"),
        }
        for mode, (profile, sandbox) in cases.items():
            with self.subTest(mode=mode):
                result = self.run_lane(mode, "--", "bounded task")
                self.assertEqual(result.returncode, 0, result.stderr)
                args = self.captured_args()
                self.assertEqual(args[args.index("--profile") + 1], profile)
                self.assertEqual(args[args.index("--sandbox") + 1], sandbox)
                self.assertIn("--ephemeral", args)
                self.assertIn("--strict-config", args)

    def test_review_modes_use_review_schema(self):
        for invocation in (
            ("plan-review", "--plan", "plan.md", "--", "review plan"),
            ("code-review", "--base", "HEAD", "--", "review diff"),
        ):
            with self.subTest(mode=invocation[0]):
                result = self.run_lane(*invocation)
                self.assertEqual(result.returncode, 0, result.stderr)
                args = self.captured_args()
                schema = args[args.index("--output-schema") + 1]
                self.assertTrue(schema.endswith("/schemas/review.json"))

    def test_spark_write_requires_explicit_flag(self):
        result = self.run_lane("spark", "--write", "--", "rename one key")
        self.assertEqual(result.returncode, 0, result.stderr)
        args = self.captured_args()
        self.assertEqual(args[args.index("--sandbox") + 1], "workspace-write")
        self.assertIn("one file", self.prompt_file.read_text(encoding="utf-8"))

    def test_write_flag_is_rejected_for_other_modes(self):
        result = self.run_lane("implement", "--write", "--", "task")
        self.assertEqual(result.returncode, 2)
        self.assertIn("only valid for spark", result.stderr)

    def test_plan_must_stay_inside_repository(self):
        outside = self.root / "outside.md"
        outside.write_text("# Outside\n", encoding="utf-8")
        result = self.run_lane("plan-review", "--plan", str(outside), "--", "review")
        self.assertEqual(result.returncode, 1)
        self.assertIn("inside repository", result.stderr)

    def test_worker_timeout_is_bounded(self):
        self.env |= {
            "CODEX_LANE_TIMEOUT_SECONDS": "1",
            "FAKE_CODEX_SLEEP": "5",
        }
        result = self.run_lane("discover", "--", "slow task")
        self.assertEqual(result.returncode, 124)
        self.assertIn("timed out after 1 seconds", result.stderr)


if __name__ == "__main__":
    unittest.main()
