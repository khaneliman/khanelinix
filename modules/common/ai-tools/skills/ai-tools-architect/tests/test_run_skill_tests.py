from __future__ import annotations

import importlib.util
import os
import subprocess
import sys
import tempfile
import textwrap
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

    def test_cli_keeps_git_fixtures_isolated_from_parent_worktree(self) -> None:
        cache = Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache"))
        cache.mkdir(parents=True, exist_ok=True)
        clean_env = {
            key: value
            for key, value in os.environ.items()
            if not key.startswith("GIT_")
        }
        clean_env.update(GIT_CONFIG_GLOBAL=os.devnull, GIT_CONFIG_NOSYSTEM="1")
        for source in ("repository", "index", "parameters", "config", "global"):
            with (
                self.subTest(source=source),
                tempfile.TemporaryDirectory(
                    prefix="skill-runner-git-", dir=cache
                ) as temporary,
            ):
                scratch = Path(temporary)
                parent = scratch / "parent"
                parent.mkdir()

                def git(*args: str, cwd: Path = parent) -> str:
                    return subprocess.check_output(
                        ["git", *args], cwd=cwd, env=clean_env, text=True
                    ).strip()

                git("init", "-q", "--initial-branch=main")
                git("config", "user.name", "Parent User")
                git("config", "user.email", "parent@example.invalid")
                (parent / "tracked").write_text("keep me\n", encoding="utf-8")
                git("add", "tracked")
                git("commit", "-qm", "parent")
                worktree = scratch / "worktree"
                git("worktree", "add", "-q", "--detach", str(worktree))
                git_dir = Path(git("rev-parse", "--absolute-git-dir", cwd=worktree))
                protected = [
                    parent / ".git" / "config",
                    parent / ".git" / "index",
                    parent / ".git" / "HEAD",
                    parent / ".git" / "refs" / "heads" / "main",
                    git_dir / "HEAD",
                    git_dir / "index",
                ]
                before = {path: path.read_bytes() for path in protected}
                hooks = scratch / "hooks"
                hooks.mkdir()
                hook = hooks / "pre-commit"
                hook.write_text("#!/bin/sh\nexit 97\n", encoding="utf-8")
                hook.chmod(0o755)
                global_config = scratch / ".gitconfig"
                global_config.write_text(
                    f"[core]\n\thooksPath = {hooks}\n", encoding="utf-8"
                )
                overrides = {
                    "repository": {
                        "GIT_DIR": str(git_dir),
                        "GIT_COMMON_DIR": str(parent / ".git"),
                    },
                    "index": {
                        "GIT_WORK_TREE": str(worktree),
                        "GIT_INDEX_FILE": str(git_dir / "index"),
                        "GIT_OBJECT_DIRECTORY": str(parent / ".git" / "objects"),
                    },
                    "parameters": {
                        "GIT_CONFIG_PARAMETERS": f"'core.hooksPath={hooks}'",
                    },
                    "config": {
                        "GIT_CONFIG_COUNT": "1",
                        "GIT_CONFIG_KEY_0": "core.hooksPath",
                        "GIT_CONFIG_VALUE_0": str(hooks),
                    },
                    "global": {
                        "HOME": str(scratch),
                        "XDG_CONFIG_HOME": str(scratch / "config"),
                    },
                }
                env = dict(clean_env, FIXTURE_REPO=str(scratch / "fixture"))
                if source == "global":
                    env.pop("GIT_CONFIG_GLOBAL")
                env.update(overrides[source])
                root = worktree / "skills"
                self.write_test(
                    root,
                    "git-fixture",
                    textwrap.dedent("""\
                        import os
                        import subprocess
                        import unittest
                        from pathlib import Path

                        class TestFixture(unittest.TestCase):
                            def test_repository(self):
                                repo = Path(os.environ["FIXTURE_REPO"])
                                repo.mkdir()
                                def git(*args):
                                    return subprocess.check_output(
                                        ["git", *args], cwd=repo, text=True
                                    ).strip()
                                git("init", "-q", "--initial-branch=main")
                                git("config", "user.name", "Test User")
                                git("config", "user.email", "test@example.invalid")
                                (repo / "fixture").write_text("fixture")
                                git("add", "fixture")
                                git("commit", "-qm", "fixture")
                                self.assertEqual(git("rev-parse", "--show-toplevel"), str(repo))
                                self.assertEqual(git("show", "-s", "--format=%an"), "Test User")
                        """),
                )

                result = subprocess.run(
                    [sys.executable, "-B", str(SCRIPT.resolve()), str(root)],
                    env=env,
                    capture_output=True,
                    text=True,
                    timeout=30,
                    check=False,
                )

                for path, content in before.items():
                    self.assertEqual(content, path.read_bytes(), str(path))
                self.assertEqual(0, result.returncode, result.stdout + result.stderr)
                self.assertIn("PASS git-fixture: 1 tests", result.stdout)


if __name__ == "__main__":
    unittest.main()
