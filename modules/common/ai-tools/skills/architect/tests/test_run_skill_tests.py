from __future__ import annotations

import importlib.util
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(__file__).parents[1] / "scripts" / "run_skill_tests.py"
SPEC = importlib.util.spec_from_file_location("run_skill_tests", SCRIPT)
assert SPEC is not None and SPEC.loader is not None
run_skill_tests = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = run_skill_tests
SPEC.loader.exec_module(run_skill_tests)


class RunSkillTestsTests(unittest.TestCase):
    def write_test(self, root: Path, skill: str, body: str) -> None:
        tests = root / skill / "tests"
        tests.mkdir(parents=True)
        (tests / "test_fixture.py").write_text(body, encoding="utf-8")

    def test_discovery_is_sorted_and_ignores_noncanonical_depth(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            self.write_test(root, "zeta", "import unittest\n")
            self.write_test(root, "alpha", "import unittest\n")
            nested = root / "nested" / "child" / "tests"
            nested.mkdir(parents=True)
            (nested / "test_hidden.py").write_text("", encoding="utf-8")

            discovered = run_skill_tests.discover_test_dirs(root)

            self.assertEqual(
                [path.parent.name for path in discovered], ["alpha", "zeta"]
            )

    def test_canonical_root_includes_planning_provider_tests(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            ai_tools = Path(temporary) / "ai-tools"
            skills = ai_tools / "skills"
            self.write_test(skills, "alpha", "import unittest\n")
            adapter_tests = ai_tools / "planning-with-files" / "codex" / "tests"
            adapter_tests.mkdir(parents=True)
            (adapter_tests / "test_adapter.py").write_text(
                "import unittest\n", encoding="utf-8"
            )

            discovered = run_skill_tests.discover_test_dirs(skills)

            self.assertEqual(len(discovered), 2)
            self.assertIn(adapter_tests.resolve(), discovered)
            self.assertEqual(
                run_skill_tests.suite_name(skills, adapter_tests.resolve()),
                "planning-with-files/codex",
            )

    def test_cli_reports_pass_and_failure_with_nonzero_exit(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            self.write_test(
                root,
                "passing",
                "import unittest\n\n"
                "class TestPassing(unittest.TestCase):\n"
                "    def test_ok(self):\n"
                "        self.assertTrue(True)\n",
            )
            self.write_test(
                root,
                "failing",
                "import unittest\n\n"
                "class TestFailing(unittest.TestCase):\n"
                "    def test_bad(self):\n"
                "        self.fail('expected fixture failure')\n",
            )

            result = subprocess.run(
                [sys.executable, str(SCRIPT), str(root)],
                check=False,
                capture_output=True,
                text=True,
            )

            self.assertEqual(1, result.returncode)
            self.assertIn("PASS passing: 1 tests", result.stdout)
            self.assertIn("FAIL failing: 1 tests", result.stderr)
            self.assertIn("expected fixture failure", result.stderr)


if __name__ == "__main__":
    unittest.main()
