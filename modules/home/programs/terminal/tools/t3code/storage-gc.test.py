import os
import subprocess
import tempfile
import time
import unittest
from pathlib import Path

SCRIPT = Path(__file__).with_name("storage-gc.sh")
ENV = {
    **os.environ,
    "GIT_CONFIG_GLOBAL": os.devnull,
    "GIT_CONFIG_NOSYSTEM": "1",
}
DAY = 86400


def git(*args, cwd):
    return subprocess.run(
        ["git", *args], cwd=cwd, env=ENV, check=True, capture_output=True, text=True
    ).stdout.strip()


def age(path, seconds):
    then = time.time() - seconds
    os.utime(path, (then, then), follow_symlinks=False)


class StorageGcTests(unittest.TestCase):
    def setUp(self):
        self.scratch = tempfile.TemporaryDirectory()
        # The script reports canonical worktree paths.
        self.root = Path(self.scratch.name).resolve()
        self.repo = self.root / "repos" / "project"
        self.worktrees = self.root / "worktrees" / "project"
        self.worktrees.mkdir(parents=True)
        self.repo.mkdir(parents=True)
        git("init", "--quiet", "--initial-branch=main", cwd=self.repo)
        git("config", "user.name", "Test", cwd=self.repo)
        git("config", "user.email", "test@example.com", cwd=self.repo)
        (self.repo / "tracked.txt").write_text("base\n")
        git("add", "tracked.txt", cwd=self.repo)
        git("commit", "--quiet", "-m", "base", cwd=self.repo)

    def tearDown(self):
        self.scratch.cleanup()

    def run_gc(self, *extra):
        return subprocess.run(
            [
                "bash",
                "-euo",
                "pipefail",
                str(SCRIPT),
                "--worktree-root",
                str(self.root / "worktrees"),
                "--idle-days",
                "3",
                "--max-new-file-mib",
                "1",
                "--repo-root",
                str(self.root / "repos"),
                *extra,
            ],
            env=ENV,
            check=True,
            capture_output=True,
            text=True,
        ).stdout

    def worktree(self, name, *, idle):
        path = self.worktrees / name
        git("worktree", "add", "--quiet", "-b", name, str(path), cwd=self.repo)
        (path / "tracked.txt").write_text(f"{name} edit\n")
        (path / "new.txt").write_text("new file\n")
        if idle:
            git_dir = Path(git("rev-parse", "--absolute-git-dir", cwd=path))
            for changed in (path / "tracked.txt", path / "new.txt", git_dir / "logs" / "HEAD"):
                age(changed, 4 * DAY)
        return path

    def test_only_stale_git_temporary_objects_are_removed(self):
        objects = self.repo / ".git" / "objects"
        # Age real packs and loose objects past the expiry so fsck catches any
        # rule that deletes more than temporary files.
        (self.repo / "loose.txt").write_text("loose\n")
        git("gc", "--quiet", cwd=self.repo)
        git("add", "loose.txt", cwd=self.repo)
        git("commit", "--quiet", "-m", "loose", cwd=self.repo)
        for path in objects.rglob("*"):
            if path.is_file():
                age(path, 2 * 3600)
        stale = [objects / "pack" / "tmp_pack_stale", objects / "ab" / "tmp_obj_stale"]
        fresh = objects / "pack" / "tmp_pack_fresh"
        for path in [*stale, fresh]:
            path.parent.mkdir(exist_ok=True)
            path.write_bytes(b"partial")
        for path in stale:
            age(path, 2 * 3600)

        self.assertIn("Would remove 2 stale git temporary files", self.run_gc("--dry-run"))
        self.assertTrue(all(path.exists() for path in stale))

        self.assertIn("Removed 2 stale git temporary files", self.run_gc())
        self.assertFalse(any(path.exists() for path in stale))
        self.assertTrue(fresh.exists())
        git("fsck", "--no-dangling", cwd=self.repo)

    def test_idle_edits_are_committed_on_the_worktree_branch_without_hooks_or_signing(self):
        hooks = self.repo / ".git" / "hooks"
        for hook in ("pre-commit", "prepare-commit-msg", "commit-msg"):
            (hooks / hook).write_text("#!/bin/sh\nexit 1\n")
            (hooks / hook).chmod(0o755)
        git("config", "commit.gpgSign", "true", cwd=self.repo)
        git("config", "gpg.program", "false", cwd=self.repo)
        path = self.worktree("idle", idle=True)
        before = git("rev-parse", "idle", cwd=self.repo)

        self.assertIn("Would commit 2 idle changes on idle", self.run_gc("--dry-run"))
        self.assertEqual(git("rev-parse", "idle", cwd=self.repo), before)

        self.assertIn("Committed 2 idle changes on idle", self.run_gc())
        self.assertEqual(git("status", "--porcelain", cwd=path), "")
        self.assertEqual(git("rev-parse", "idle^", cwd=self.repo), before)
        self.assertEqual(git("show", "idle:tracked.txt", cwd=self.repo), "idle edit")
        self.assertEqual(git("show", "idle:new.txt", cwd=self.repo), "new file")

    def test_recent_oversized_nested_or_busy_worktrees_are_kept(self):
        recent = self.worktree("recent", idle=False)
        oversized = self.worktree("oversized", idle=True)
        (oversized / "large.bin").write_bytes(b"\0" * (2 * 1024 * 1024))
        age(oversized / "large.bin", 4 * DAY)
        staged = self.worktree("staged", idle=True)
        (staged / "large.bin").write_bytes(b"\0" * (2 * 1024 * 1024))
        git("add", "large.bin", cwd=staged)
        age(staged / "large.bin", 4 * DAY)
        nested = self.worktree("nested", idle=True)
        vendor = nested / "vendor"
        vendor.mkdir()
        git("init", "--quiet", cwd=vendor)
        (vendor / "lib.txt").write_text("vendored\n")
        git("add", "lib.txt", cwd=vendor)
        git("-c", "user.name=Test", "-c", "user.email=test@example.com", "commit", "--quiet", "-m", "vendor", cwd=vendor)
        age(vendor, 4 * DAY)
        busy = self.worktree("busy", idle=True)
        names = ("recent", "oversized", "staged", "nested", "busy")
        tips = {name: git("rev-parse", name, cwd=self.repo) for name in names}

        sleeper = subprocess.Popen(["sleep", "60"], cwd=busy)
        try:
            output = self.run_gc()
        finally:
            sleeper.kill()
            sleeper.wait()

        self.assertNotIn(str(recent), output)
        self.assertIn(f"Keeping {oversized}: new file large.bin exceeds 1 MiB", output)
        self.assertIn(f"Keeping {staged}: new file large.bin exceeds 1 MiB", output)
        self.assertIn(f"Keeping {nested}: untracked repository vendor/", output)
        self.assertIn(f"Keeping {busy}: a process is working in it", output)
        for name, tip in tips.items():
            self.assertEqual(git("rev-parse", name, cwd=self.repo), tip)


if __name__ == "__main__":
    unittest.main()
