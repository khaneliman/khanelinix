from __future__ import annotations

import json
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(__file__).resolve().parents[1] / "scripts/cleanup.py"


class CleanupTests(unittest.TestCase):
    def setUp(self):
        cache = Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache"))
        cache.mkdir(parents=True, exist_ok=True)
        self.scratch = tempfile.TemporaryDirectory(
            prefix="git-cleanup-tests-", dir=cache
        )
        self.addCleanup(self.scratch.cleanup)
        self.root = Path(self.scratch.name)
        self.repo = self.root / "repo"
        self.repo.mkdir()
        self.env = {k: v for k, v in os.environ.items() if not k.startswith("GIT_")}
        self.env.update({"GIT_CONFIG_NOSYSTEM": "1", "GIT_CONFIG_GLOBAL": os.devnull})
        self.git("init", "-q", "-b", "main")
        self.git("config", "user.name", "Cleanup Test")
        self.git("config", "user.email", "cleanup@example.invalid")
        self.git("config", "commit.gpgsign", "false")
        (self.repo / "file").write_text("base\n")
        (self.repo / ".gitignore").write_text("ignored\n")
        self.git("add", ".")
        self.git("commit", "-qm", "base")
        self.base = self.git("rev-parse", "HEAD")
        self.worktree = self.root / "worker space"
        self.git("worktree", "add", "-qb", "topic", str(self.worktree))
        (self.worktree / "file").write_text("changed\n")
        self.git("add", "file", cwd=self.worktree)
        self.git("commit", "-qm", "worker", cwd=self.worktree)
        self.tip = self.git("rev-parse", "HEAD", cwd=self.worktree)

    def git(self, *args, cwd=None):
        return subprocess.run(
            ["git", "-C", str(cwd or self.repo), *args],
            env=self.env,
            capture_output=True,
            text=True,
            check=True,
        ).stdout.strip()

    def run_cleanup(
        self, *extra, branch=True, worktree=True, expected=None, target="main", env=None
    ):
        command = [
            sys.executable,
            str(SCRIPT),
            "--repo",
            str(self.repo),
            "--expected-tip",
            expected or self.tip,
            "--target",
            target,
        ]
        if branch:
            command += ["--branch", "topic"]
        if worktree:
            command += ["--worktree", str(self.worktree)]
        process = subprocess.run(
            command + list(extra),
            cwd=self.repo,
            env=env or self.env,
            capture_output=True,
            text=True,
            check=False,
        )
        return process.returncode, json.loads(process.stdout)

    def assertBlocked(self, *extra, **kwargs):
        code, result = self.run_cleanup("--apply", *extra, **kwargs)
        self.assertEqual(code, 1, result)
        self.assertEqual(result["state"], "blocked")
        self.assertTrue(self.worktree.exists())
        self.assertEqual(self.git("rev-parse", "topic"), self.tip)

    def test_preview_apply_and_retry_preserve_main_and_unrelated_branch(self):
        self.git("merge", "--ff-only", "topic")
        self.git("branch", "unrelated")
        (self.repo / "untracked").write_text("user work")
        before = self.git("status", "--porcelain")
        self.assertEqual(self.run_cleanup()[1]["state"], "ready")
        self.assertTrue(self.worktree.exists())
        code, result = self.run_cleanup("--apply")
        self.assertEqual(code, 0, result)
        self.assertEqual(result["state"], "cleaned")
        self.assertFalse(self.worktree.exists())
        self.assertEqual(self.git("branch", "--list", "topic"), "")
        self.assertEqual(self.git("rev-parse", "unrelated"), self.tip)
        self.assertEqual(self.git("status", "--porcelain"), before)
        self.assertEqual(self.run_cleanup("--apply")[1]["state"], "already-clean")

    def test_unintegrated_tip_is_retained(self):
        self.assertBlocked()

    def test_stale_tip_is_retained(self):
        self.git("merge", "--ff-only", "topic")
        self.assertBlocked(expected=self.base)

    def test_dirty_untracked_and_ignored_files_are_retained(self):
        self.git("merge", "--ff-only", "topic")
        for name in ("file", "untracked", "ignored"):
            with self.subTest(name=name):
                path = self.worktree / name
                original = path.read_bytes() if path.exists() else None
                path.write_text("keep me\n")
                self.assertBlocked()
                if original is None:
                    path.unlink()
                else:
                    path.write_bytes(original)

    def test_locked_worktree_is_retained(self):
        self.git("merge", "--ff-only", "topic")
        self.git("worktree", "lock", str(self.worktree), "--reason", "active worker")
        self.assertBlocked()

    def test_index_flags_cannot_hide_modified_files(self):
        self.git("merge", "--ff-only", "topic")
        for flag in ("assume-unchanged", "skip-worktree"):
            with self.subTest(flag=flag):
                self.git("update-index", "--" + flag, "file", cwd=self.worktree)
                (self.worktree / "file").write_text("hidden user work\n")
                self.assertEqual(
                    self.git("status", "--porcelain", cwd=self.worktree), ""
                )
                self.assertBlocked()
                self.assertEqual(
                    (self.worktree / "file").read_text(), "hidden user work\n"
                )
                self.git("update-index", "--no-" + flag, "file", cwd=self.worktree)
                (self.worktree / "file").write_text("changed\n")

    def test_branch_in_unselected_worktree_is_retained(self):
        self.git("merge", "--ff-only", "topic")
        self.assertBlocked(worktree=False)

    def test_primary_worktree_is_retained(self):
        self.git("switch", "-q", "--detach")
        self.git("switch", "-q", "--detach", cwd=self.worktree)
        self.git("switch", "-q", "topic")
        self.git("branch", "-f", "main", "topic")
        self.worktree = self.repo
        self.assertBlocked()

    def test_in_progress_operation_is_retained(self):
        self.git("merge", "--ff-only", "topic")
        marker = Path(
            self.git(
                "rev-parse",
                "--path-format=absolute",
                "--git-path",
                "MERGE_HEAD",
                cwd=self.worktree,
            )
        )
        marker.write_text(self.base)
        self.assertBlocked()

    def test_target_cannot_be_branch_being_deleted(self):
        self.assertBlocked(target="topic")

    def test_multi_commit_squash_requires_matching_landing(self):
        (self.worktree / "second").write_text("second change\n")
        self.git("add", "second", cwd=self.worktree)
        self.git("commit", "-qm", "second", cwd=self.worktree)
        self.tip = self.git("rev-parse", "topic")
        self.git("merge", "--squash", "topic")
        self.git("commit", "-qm", "squashed")
        landed = self.git("rev-parse", "HEAD")
        self.assertBlocked()
        code, result = self.run_cleanup(
            "--apply", "--source-base", self.base, "--landed-commit", landed
        )
        self.assertEqual(code, 0, result)
        self.assertEqual(result["integration"], "exact-landed-diff")

    def test_mismatched_landing_preserves_source(self):
        (self.repo / "file").write_text("different change\n")
        self.git("commit", "-qam", "different")
        self.assertBlocked(
            "--source-base", self.base, "--landed-commit", self.git("rev-parse", "HEAD")
        )

    def test_diff_configuration_cannot_hide_unintegrated_gitlink(self):
        self.git(
            "update-index",
            "--add",
            "--cacheinfo",
            "160000",
            self.base,
            "sub",
            cwd=self.worktree,
        )
        self.git("commit", "-qm", "gitlink", cwd=self.worktree)
        (self.worktree / "sub").mkdir()
        self.tip = self.git("rev-parse", "topic")
        (self.repo / "file").write_text("changed\n")
        self.git("commit", "-qam", "partial landing")
        landed = self.git("rev-parse", "HEAD")
        self.git("config", "diff.ignoreSubmodules", "all")
        self.git("config", "diff.submodule", "log")
        code, result = self.run_cleanup(
            "--apply",
            "--source-base",
            self.base,
            "--landed-commit",
            landed,
        )
        self.assertEqual(code, 1, result)
        self.assertIn("do not exactly match", result["reason"])
        self.assertTrue(self.worktree.exists())
        self.assertEqual(self.git("rev-parse", "topic"), self.tip)

    def test_detached_worktree_cleanup(self):
        self.git("merge", "--ff-only", "topic")
        self.git("switch", "-q", "--detach", cwd=self.worktree)
        code, result = self.run_cleanup("--apply", branch=False)
        self.assertEqual(code, 0, result)
        self.assertFalse(self.worktree.exists())
        self.assertEqual(self.git("rev-parse", "topic"), self.tip)

    def test_branch_only_cleanup(self):
        self.git("merge", "--ff-only", "topic")
        self.git("worktree", "remove", str(self.worktree))
        code, result = self.run_cleanup("--apply", worktree=False)
        self.assertEqual(code, 0, result)
        self.assertEqual(self.git("branch", "--list", "topic"), "")

    def test_inherited_git_dir_does_not_redirect_cleanup(self):
        self.git("merge", "--ff-only", "topic")
        env = dict(
            self.env,
            GIT_DIR=str(self.root / "nonexistent"),
            GIT_WORK_TREE=str(self.root),
        )
        code, result = self.run_cleanup("--apply", env=env)
        self.assertEqual(code, 0, result)
        self.assertEqual(self.git("rev-parse", "HEAD"), self.tip)


if __name__ == "__main__":
    unittest.main()
