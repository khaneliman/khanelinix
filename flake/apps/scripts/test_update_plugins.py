#!/usr/bin/env python3

import importlib.util
import io
import json
import os
import subprocess
import tempfile
import threading
import unittest
from pathlib import Path
from unittest.mock import patch

from rich.console import Console

SCRIPT = Path(__file__).with_name("update_plugins.py")
SPEC = importlib.util.spec_from_file_location("update_plugins", SCRIPT)
assert SPEC and SPEC.loader
update_plugins = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(update_plugins)


class UpdatePluginsTests(unittest.TestCase):
    def setUp(self):
        scratch_root = Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache"))
        scratch_root.mkdir(parents=True, exist_ok=True)
        self.scratch = tempfile.TemporaryDirectory(
            prefix="update-plugins-test-", dir=scratch_root
        )
        self.addCleanup(self.scratch.cleanup)
        self.root = Path(self.scratch.name)
        self.environment = patch.dict(
            os.environ,
            {
                "GITHUB_TOKEN": "fixture-only",
                "GIT_CONFIG_GLOBAL": os.devnull,
                "GIT_CONFIG_SYSTEM": os.devnull,
                "NIXPKGS_UPDATE_OUTCOME_DIR": str(self.root / "outcomes"),
                "NIXPKGS_UPDATE_BASE_SHA": "fixture-base",
                "NIXPKGS_UPDATE_INVOCATION_ID": "fixture-invocation",
            },
        )
        self.environment.start()
        self.addCleanup(self.environment.stop)
        update_plugins.task_state.clear()
        update_plugins.worktrees.clear()
        self.output = io.StringIO()
        self.enterContext(
            patch.object(
                update_plugins, "console", Console(file=self.output, width=200)
            )
        )
        self.enterContext(
            patch.object(update_plugins, "Path", side_effect=self.redirect_log)
        )
        self.repo = self.init_repository("vim")
        self.before = self.git(self.repo, "rev-parse", "HEAD").stdout.strip()

    def redirect_log(self, value):
        path = Path(value)
        if path.parent == Path("/tmp") and path.name.endswith("-update.log"):
            return self.root / path.name
        return path

    def git(self, repo, *args):
        return subprocess.run(
            ("git", *args), cwd=repo, check=True, capture_output=True, text=True
        )

    def init_repository(self, name):
        repo = self.root / name
        repo.mkdir()
        self.git(repo, "init", "--quiet")
        self.git(repo, "config", "user.name", "Updater Test")
        self.git(repo, "config", "user.email", "updater@example.invalid")
        self.git(repo, "config", "commit.gpgsign", "false")
        self.git(repo, "config", "core.hooksPath", str(repo / ".git" / "hooks"))
        (repo / "plugin.txt").write_text("before\n")
        self.git(repo, "add", "-A")
        self.git(repo, "commit", "--quiet", "-m", "test: baseline")
        update_plugins.worktrees[name] = {"path": str(repo), "branch": "fixture"}
        return repo

    def task(
        self,
        name="vim",
        command="printf 'after\\n' > plugin.txt",
        self_committing=False,
    ):
        return {
            "worktree": name,
            "command": command,
            "self_committing": self_committing,
            "depends_on": None,
        }

    def run_task(self, **kwargs):
        event = threading.Event()
        update_plugins.run_update_in_worktree(
            "vim", self.task(**kwargs), {"vim": event}
        )
        self.assertTrue(event.is_set())
        return update_plugins.task_state["vim"]

    def assert_outcome(self, status):
        row = json.loads((self.root / "outcomes" / "vim.json").read_text())
        self.assertEqual(status, row["status"])
        self.assertEqual("fixture-invocation", row["invocation_id"])

    def assert_failure(self, state, message):
        self.assertEqual("ERROR", state["status"])
        self.assertTrue(state["error"])
        output = "\n".join(state["output_lines"])
        self.assertIn(message, output)
        self.assertNotIn("No changes to commit", output)

    def test_no_change_skips_commit_and_checkpoints_success(self):
        hook = self.repo / ".git" / "hooks" / "pre-commit"
        hook.write_text("#!/bin/sh\nexit 1\n")
        hook.chmod(0o755)
        state = self.run_task(command="true")
        self.assertEqual("COMPLETE", state["status"])
        self.assertFalse(state["error"])
        self.assertIn("No changes to commit", state["output_lines"])
        self.assertEqual(
            self.before, self.git(self.repo, "rev-parse", "HEAD").stdout.strip()
        )
        self.assert_outcome("COMPLETE")

    def test_changed_plugin_is_committed(self):
        state = self.run_task()
        self.assertEqual("COMPLETE", state["status"])
        self.assertFalse(state["error"])
        self.assertNotEqual(
            self.before, self.git(self.repo, "rev-parse", "HEAD").stdout.strip()
        )
        self.assertEqual("", self.git(self.repo, "status", "--porcelain").stdout)
        self.assertEqual("plugin.txt\n", self.git(self.repo, "ls-files").stdout)
        self.assertTrue(
            self.git(self.repo, "log", "-1", "--format=%s").stdout.startswith(
                "vimPlugins: update "
            )
        )
        self.assert_outcome("COMPLETE")

    def test_rejected_commit_preserves_hook_output(self):
        hook = self.repo / ".git" / "hooks" / "pre-commit"
        hook.write_text("#!/bin/sh\necho hook-stdout\necho hook-stderr >&2\nexit 1\n")
        hook.chmod(0o755)
        state = self.run_task()
        self.assert_failure(state, "git commit failed (1)")
        self.assertIn("hook-stdout", "\n".join(state["output_lines"]))
        self.assertIn("hook-stderr", "\n".join(state["output_lines"]))
        self.assertEqual(
            self.before, self.git(self.repo, "rev-parse", "HEAD").stdout.strip()
        )
        self.assert_outcome("FAILED")

    def test_index_lock_fails_staging(self):
        (self.repo / ".git" / "index.lock").touch()
        state = self.run_task()
        self.assert_failure(state, "git add failed (128)")
        self.assertIn("index.lock", "\n".join(state["output_lines"]))
        self.assertEqual(
            self.before, self.git(self.repo, "rev-parse", "HEAD").stdout.strip()
        )
        self.assert_outcome("FAILED")

    def test_corrupt_index_fails_diff(self):
        original_run = update_plugins.run_command
        results = []

        def corrupt_after_staging(command, **kwargs):
            result = original_run(command, **kwargs)
            results.append((command, result.returncode))
            if command == "git add -A":
                (self.repo / ".git" / "index").write_bytes(b"corrupt index")
            return result

        with patch.object(
            update_plugins, "run_command", side_effect=corrupt_after_staging
        ):
            state = self.run_task()
        self.assert_failure(state, "git diff failed (128)")
        self.assertEqual(
            [("git add -A", 0), ("git diff --cached --quiet", 128)], results
        )

    def test_updater_failure_checkpoints_and_signals(self):
        self.assert_failure(
            self.run_task(command="exit 7"), "Command failed with code 7"
        )
        self.assert_outcome("FAILED")

    def test_checkpoint_failure_still_signals(self):
        blocked = self.root / "blocked"
        blocked.write_text("not a directory")
        with patch.dict(os.environ, {"NIXPKGS_UPDATE_OUTCOME_DIR": str(blocked)}):
            self.assert_failure(self.run_task(), "File exists")

    def test_setup_exception_still_checkpoints_and_signals(self):
        event = threading.Event()
        with patch.object(update_plugins, "persist_task_outcome") as checkpoint:
            update_plugins.run_update_in_worktree("vim", {}, {"vim": event})
        self.assertTrue(event.is_set())
        checkpoint.assert_called_once_with("vim")
        self.assertTrue(update_plugins.task_state["vim"]["error"])

    def test_self_committing_updater_is_not_recommitted(self):
        state = self.run_task(
            command="printf 'after\\n' > plugin.txt && git add -A && git commit -m 'upstream: update'",
            self_committing=True,
        )
        self.assertEqual("COMPLETE", state["status"])
        self.assertEqual(
            "upstream: update\n", self.git(self.repo, "log", "-1", "--format=%s").stdout
        )
        self.assert_outcome("COMPLETE")

    def test_main_mixed_and_all_success_summaries(self):
        lua = self.init_repository("lua")
        for command, expected in (("exit 9", 1), ("true", 0)):
            with self.subTest(command=command):
                update_plugins.task_state.clear()
                self.output.seek(0)
                self.output.truncate()
                tasks = {
                    "vim": self.task(command="true"),
                    "lua": self.task("lua", command),
                }
                with (
                    patch.object(update_plugins, "TASKS", tasks),
                    patch.object(update_plugins, "setup_full_worktree") as setup,
                    patch.object(
                        update_plugins, "run_command", wraps=update_plugins.run_command
                    ) as run,
                ):
                    self.assertEqual(expected, update_plugins.main())
                self.assertEqual(2, setup.call_count)
                self.assertFalse(
                    any("checkout" in call.args[0] for call in run.call_args_list)
                )
                summary = self.output.getvalue()
                if expected:
                    self.assertIn("Some updates failed", summary)
                    self.assertNotIn("All updates are complete", summary)
                else:
                    self.assertIn("All updates are complete", summary)
                self.assertEqual("", self.git(lua, "status", "--porcelain").stdout)

    def test_main_requires_complete_without_error(self):
        for status, error in (("RUNNING", False), ("COMPLETE", True)):
            with self.subTest(status=status, error=error):
                update_plugins.task_state.clear()

                def finish(name, details, events, status=status, error=error):
                    update_plugins.update_task_state(name, status=status, error=error)
                    events[name].set()

                with (
                    patch.object(update_plugins, "TASKS", {"vim": self.task()}),
                    patch.object(update_plugins, "setup_full_worktree"),
                    patch.object(
                        update_plugins, "run_update_in_worktree", side_effect=finish
                    ),
                ):
                    self.assertEqual(1, update_plugins.main())


if __name__ == "__main__":
    unittest.main()
