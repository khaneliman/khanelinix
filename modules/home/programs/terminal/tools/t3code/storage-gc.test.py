import os
import sqlite3
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


def age_tree(path, seconds):
    for parent, _, files in os.walk(path, topdown=False):
        for name in files:
            age(Path(parent) / name, seconds)
        age(parent, seconds)


def write(path, text="x"):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text)
    return path


class StorageGcTests(unittest.TestCase):
    def setUp(self):
        self.scratch = tempfile.TemporaryDirectory()
        # The script reports canonical worktree paths.
        self.root = Path(self.scratch.name).resolve()
        self.repo = self.root / "repos" / "project"
        self.t3_home = self.root / "t3"
        self.worktrees = self.t3_home / "worktrees" / "project"
        self.worktrees.mkdir(parents=True)
        self.repo.mkdir(parents=True)
        git("init", "--quiet", "--initial-branch=main", cwd=self.repo)
        git("config", "user.name", "Test", cwd=self.repo)
        git("config", "user.email", "test@example.com", cwd=self.repo)
        (self.repo / "tracked.txt").write_text("base\n")
        (self.repo / ".gitignore").write_text("/target/\n/scratch/\n")
        git("add", "tracked.txt", ".gitignore", cwd=self.repo)
        git("commit", "--quiet", "-m", "base", cwd=self.repo)
        # Missing and non-repository projects are skipped.
        plain = self.root / "plain"
        plain.mkdir()
        (self.t3_home / "userdata").mkdir()
        self.projects(
            "CREATE TABLE projection_projects (workspace_root TEXT NOT NULL, deleted_at TEXT)",
            ("INSERT INTO projection_projects VALUES (?, ?)", [
                (str(self.repo), None),
                (str(self.root / "missing"), None),
                (str(plain), None),
            ]),
        )

    def tearDown(self):
        self.scratch.cleanup()

    def projects(self, *statements):
        db = sqlite3.connect(self.t3_home / "userdata" / "statev2.sqlite")
        try:
            for statement in statements:
                if isinstance(statement, tuple):
                    db.executemany(*statement)
                else:
                    db.execute(statement)
            db.commit()
        finally:
            db.close()

    def run_gc(self, *extra, check=True, cwd=None):
        result = subprocess.run(
            [
                "bash",
                "-euo",
                "pipefail",
                str(SCRIPT),
                "--t3-home",
                str(self.t3_home),
                "--idle-days",
                "3",
                "--max-new-file-mib",
                "1",
                "--folder-days",
                "14",
                "--cache-hours",
                "24",
                *extra,
            ],
            env=ENV,
            check=check,
            capture_output=True,
            text=True,
            cwd=cwd,
        )
        return result.stdout if check else result

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
        removed = self.root / "repos" / "removed"
        git("init", "--quiet", str(removed), cwd=self.root)
        self.projects(("INSERT INTO projection_projects VALUES (?, ?)", [(str(removed), "2026-01-01")]))
        unlisted = removed / ".git" / "objects" / "pack" / "tmp_pack_stale"
        for path in [*stale, fresh, unlisted]:
            path.parent.mkdir(exist_ok=True)
            path.write_bytes(b"partial")
        for path in [*stale, unlisted]:
            age(path, 2 * 3600)

        self.assertIn("Would remove 2 stale git temporary files", self.run_gc("--dry-run"))
        self.assertTrue(all(path.exists() for path in stale))

        self.assertIn("Removed 2 stale git temporary files", self.run_gc())
        self.assertFalse(any(path.exists() for path in stale))
        self.assertTrue(fresh.exists() and unlisted.exists())
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

    def test_old_folders_and_idle_cargo_output_in_target_directories_are_pruned(self):
        target = self.repo / "target"
        write(target / ".rustc_info.json")
        old_run = write(target / "old-run" / "frame.png").parent
        old_cache = write(old_run / "cargo-cache" / "CACHEDIR.TAG").parent
        write(old_cache / "debug" / ".cargo-lock")
        frozen = write(target / "frozen-run" / "assets" / "mesh.glb").parent
        after_frozen = write(target / "later-run" / "frame.png").parent
        untagged = write(target / "untagged-run" / ".rustc_info.json").parent
        write(untagged / "debug" / ".cargo-lock")
        recent_run = write(target / "recent-run" / "frame.png").parent
        profile = write(target / "debug" / ".cargo-lock").parent
        triple = write(target / "wasm32-unknown-unknown" / "release" / ".cargo-lock").parent.parent
        tracked_run = write(target / "tracked-run" / "receipt.json").parent
        busy_run = write(target / "busy-run" / "frame.png").parent
        odd_busy_run = write(target / "busy\\brun" / "frame.png").parent
        git("add", "-f", "target/tracked-run/receipt.json", cwd=self.repo)
        git("commit", "--quiet", "-m", "tracked run", cwd=self.repo)
        # Only ignored cargo target directories at the top of a worktree are
        # pruned, in every worktree of a project's repository. Other tools
        # tag non-scratch state, such as uv virtual environments, as caches.
        venv_bin = write(self.repo / "scratch" / "bin" / "python").parent
        write(venv_bin.parent / "CACHEDIR.TAG")
        unignored_run = write(self.repo / "fixtures" / "old-run" / "frame.png").parent
        write(unignored_run.parent / ".rustc_info.json")
        linked = self.worktree("builds", idle=False)
        linked_run = write(linked / "target" / "old-run" / "frame.png").parent
        write(linked / "target" / ".rustc_info.json")
        # A checkout anywhere inside a folder keeps it, even under a name
        # cargo uses for its internals.
        nested = target / "checkout-run"
        checkout = nested / "deps" / "agent-checkout"
        git("worktree", "add", "--quiet", "-b", "agent-checkout", str(checkout), cwd=self.repo)
        nested_edit = write(checkout / "tracked.txt", "agent edit\n")
        for folder in (old_run, frozen.parent, after_frozen, untagged, profile, triple, tracked_run, busy_run,
                       odd_busy_run, venv_bin, unignored_run, linked_run, nested):
            age_tree(folder, 20 * DAY)
        frozen.chmod(0o555)

        active_run = target / "active-run"
        idle_target = write(active_run / "cargo-cache-idle" / "CACHEDIR.TAG").parent
        write(idle_target / "debug" / ".cargo-lock")
        write(idle_target / "debug" / "deps" / "libgame.rlib")
        saved_log = write(idle_target / "t01" / "check.log")
        direct = write(target / "direct-run" / ".rustc_info.json").parent
        write(direct / "debug" / ".cargo-lock")
        direct_log = write(direct / "check.log")
        locked_target = write(active_run / "cargo-cache-locked" / "CACHEDIR.TAG").parent
        lock = write(locked_target / "debug" / ".cargo-lock")
        fresh_target = write(active_run / "cargo-cache-fresh" / "CACHEDIR.TAG").parent
        write(fresh_target / "debug" / ".cargo-lock")
        for folder in (idle_target, direct, locked_target):
            age_tree(folder, 2 * DAY)
        write(active_run / "check.log")

        preview = self.run_gc("--dry-run")
        self.assertIn(f"Would remove {old_run} (folder idle 14+ days", preview)
        self.assertTrue(old_run.exists() and (idle_target / "debug").exists())

        holder = subprocess.Popen(["flock", "--exclusive", str(lock), "sleep", "60"])
        sleeper = subprocess.Popen(["sleep", "60"], cwd=busy_run)
        odd_sleeper = subprocess.Popen(["sleep", "60"], cwd=odd_busy_run)
        try:
            while subprocess.run(["flock", "--nonblock", "--shared", str(lock), "true"]).returncode == 0:
                time.sleep(0.05)
            output = self.run_gc()
        finally:
            for process in (holder, sleeper, odd_sleeper):
                process.kill()
                process.wait()

        for removed in (old_run, frozen.parent, after_frozen, untagged, linked_run):
            self.assertIn(f"Removed {removed} (folder idle 14+ days", output)
            self.assertFalse(removed.exists(), removed)
        for build in (idle_target / "debug", direct / "debug"):
            self.assertIn(f"Removed {build} (cargo build output idle 24+ hours", output)
            self.assertFalse(build.exists(), build)
        self.assertIn(f"Keeping {locked_target}: a build or process is using it", output)
        self.assertIn(f"Keeping {tracked_run}: it contains tracked files", output)
        self.assertIn(f"Keeping {busy_run}: a process is working in it", output)
        self.assertIn(f"Keeping {odd_busy_run}: a process is working in it", output)
        self.assertIn(f"Keeping {nested}: it contains a git checkout", output)
        self.assertEqual(nested_edit.read_text(), "agent edit\n")
        for kept in (target, saved_log, direct_log, recent_run, profile, triple, tracked_run,
                     busy_run, odd_busy_run, active_run, locked_target / "debug", fresh_target / "debug",
                     venv_bin, unignored_run):
            self.assertTrue(kept.exists(), kept)


    def test_a_failed_removal_does_not_stop_later_folders(self):
        target = self.repo / "target"
        write(target / ".rustc_info.json")
        stuck = write(target / "a-stuck" / "locked" / "frame.png").parent
        later = write(target / "b-later" / "frame.png").parent
        for folder in (stuck.parent, later):
            age_tree(folder, 20 * DAY)
        stuck.chmod(0)
        try:
            result = self.run_gc(check=False)
        finally:
            stuck.chmod(0o755)
        self.assertEqual(result.returncode, 1)
        self.assertIn(f"Removed {later} (folder idle 14+ days", result.stdout)
        self.assertFalse(later.exists())

    def test_an_unreadable_project_list_fails_the_run_after_the_worktree_pass(self):
        self.projects("ALTER TABLE projection_projects RENAME TO projects")
        self.worktree("idle", idle=True)
        result = self.run_gc(check=False)
        self.assertEqual(result.returncode, 1)
        self.assertIn("projection_projects", result.stderr)
        self.assertIn("Committed 2 idle changes on idle", result.stdout)

    def test_no_projects_cleans_nothing_even_inside_a_repository(self):
        self.projects("UPDATE projection_projects SET deleted_at = '2026-01-01'")
        write(self.repo / "target" / ".rustc_info.json")
        age_tree(write(self.repo / "target" / "old-run" / "frame.png").parent, 20 * DAY)
        self.assertNotIn("Would remove", self.run_gc("--dry-run", cwd=self.repo))


if __name__ == "__main__":
    unittest.main()
