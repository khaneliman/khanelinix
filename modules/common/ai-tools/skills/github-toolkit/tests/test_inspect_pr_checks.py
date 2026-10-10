from __future__ import annotations

import contextlib
import importlib.util
import io
import json
import sys
import unittest
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import patch

SCRIPT = Path(__file__).parents[1] / "scripts" / "inspect_pr_checks.py"
SPEC = importlib.util.spec_from_file_location("inspect_pr_checks", SCRIPT)
checks = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = checks
SPEC.loader.exec_module(checks)


class FetchChecksTests(unittest.TestCase):
    def test_failed_and_pending_json_survives_compatibility_fallback(self):
        primary = checks.GhResult(
            1,
            "",
            "Unknown JSON field: conclusion\nAvailable fields:\n  name\n  state\n  bucket\n  link\n",
        )
        for code, bucket in ((1, "fail"), (8, "pending")):
            with self.subTest(code=code):
                rows = [{"name": "unit", "bucket": bucket}]
                with patch.object(
                    checks,
                    "run_gh_command",
                    side_effect=[primary, checks.GhResult(code, json.dumps(rows), "")],
                ) as run:
                    self.assertEqual(checks.fetch_checks("7", Path.cwd()), rows)
                self.assertEqual(run.call_args.args[0][-1], "name,state,bucket,link")
                self.assertEqual(checks.is_failing(rows[0]), code == 1)

    def test_primary_outcome_json_is_accepted(self):
        for code in (0, 1, 8):
            with (
                self.subTest(code=code),
                patch.object(
                    checks,
                    "run_gh_command",
                    return_value=checks.GhResult(code, '[{"name":"unit"}]', ""),
                ),
            ):
                self.assertEqual(
                    checks.fetch_checks("7", Path.cwd()), [{"name": "unit"}]
                )

    def test_main_analyzes_failed_fallback_checks(self):
        primary = checks.GhResult(
            1,
            "",
            "Unknown JSON field: conclusion\nAvailable fields:\n  name\n  bucket\n",
        )
        rows = [{"name": "unit", "bucket": "fail"}]
        args = SimpleNamespace(repo=".", pr="7", max_lines=160, context=30, json=True)
        with (
            patch.object(checks, "parse_args", return_value=args),
            patch.object(checks, "find_git_root", return_value=Path.cwd()),
            patch.object(checks, "ensure_gh_available", return_value=True),
            patch.object(
                checks,
                "run_gh_command",
                side_effect=[primary, checks.GhResult(1, json.dumps(rows), "")],
            ),
            patch.object(
                checks, "analyze_check", wraps=checks.analyze_check
            ) as analyze,
            contextlib.redirect_stdout(io.StringIO()) as stdout,
        ):
            self.assertEqual(checks.main(), 1)
        analyze.assert_called_once()
        self.assertEqual(json.loads(stdout.getvalue())["results"][0]["name"], "unit")

    def test_bad_results_are_not_checks(self):
        for code, stdout in ((1, ""), (8, "not JSON"), (1, "{}"), (2, "[]")):
            with (
                self.subTest(code=code, stdout=stdout),
                patch.object(
                    checks,
                    "run_gh_command",
                    return_value=checks.GhResult(code, stdout, "transport failed"),
                ),
                contextlib.redirect_stderr(io.StringIO()),
            ):
                self.assertIsNone(checks.fetch_checks("7", Path.cwd()))


if __name__ == "__main__":
    unittest.main()
