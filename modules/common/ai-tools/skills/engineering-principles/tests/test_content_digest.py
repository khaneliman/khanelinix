from __future__ import annotations

import json
import os
import subprocess
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(__file__).resolve().parents[1] / "scripts" / "content_digest.py"


def init_repo(path: Path) -> None:
    subprocess.check_call(["git", "init", "-q"], cwd=path)
    subprocess.check_call(
        ["git", "config", "user.email", "test@example.invalid"], cwd=path
    )
    subprocess.check_call(["git", "config", "user.name", "Digest Test"], cwd=path)


class ContentDigestTests(unittest.TestCase):
    def setUp(self) -> None:
        self.directory = tempfile.TemporaryDirectory()
        self.repo = Path(self.directory.name)
        self.git("init", "-q")
        self.git("config", "user.email", "test@example.invalid")
        self.git("config", "user.name", "Digest Test")
        (self.repo / "before").write_bytes(b"before\x00binary\xff\n")
        self.git("add", "before")
        self.git("commit", "-qm", "base")

    def tearDown(self) -> None:
        self.directory.cleanup()

    def git(self, *args: str) -> bytes:
        return subprocess.check_output(["git", *args], cwd=self.repo)

    def run_tool(
        self,
        *args: str,
        env: dict[str, str] | None = None,
    ) -> subprocess.CompletedProcess[bytes]:
        command = ["python3", str(SCRIPT), "--repo", str(self.repo), *args]
        return subprocess.run(
            command, cwd=self.repo.parent, capture_output=True, env=env
        )

    def digest(
        self,
        *args: str,
        expected: str | None = None,
        env: dict[str, str] | None = None,
    ) -> dict[str, object]:
        command = ["python3", str(SCRIPT), "--repo", str(self.repo), *args]
        if expected is not None:
            command.extend(["--expected-digest", expected])
        return json.loads(
            subprocess.check_output(command, cwd=self.repo.parent, env=env)
        )

    def test_version_is_explicit(self) -> None:
        output = subprocess.check_output(["python3", str(SCRIPT), "--version"])
        self.assertEqual(output.decode().strip(), "content-digest 2")

    def test_staged_and_committed_digest_match_for_binary_rename(self) -> None:
        (self.repo / "before").rename(self.repo / "after")
        self.git("add", "-A")
        staged = self.digest("--staged")
        self.git("commit", "-qm", "rename")
        commit = self.git("rev-parse", "HEAD").strip().decode()
        committed = self.digest("--committed", commit)
        self.assertEqual(staged["digest"], committed["digest"])
        self.assertEqual(staged["changes"], 2)

    def test_expected_digest_detects_candidate_change(self) -> None:
        (self.repo / "before").write_bytes(b"candidate one")
        self.git("add", "before")
        expected = self.digest("--staged")["digest"]
        (self.repo / "before").write_bytes(b"candidate two")
        self.git("add", "before")
        command = [
            "python3",
            str(SCRIPT),
            "--repo",
            str(self.repo),
            "--staged",
            "--expected-digest",
            str(expected),
        ]
        result = subprocess.run(command, cwd=self.repo, capture_output=True)
        self.assertEqual(result.returncode, 1)
        self.assertEqual(json.loads(result.stdout)["digest_match"], False)

    def test_new_delete_and_mode_changes_match_after_commit(self) -> None:
        (self.repo / "before").unlink()
        added = self.repo / "executable"
        added.write_bytes(b"#!/bin/sh\nprintf 'binary\\000payload\\n'\n")
        added.chmod(0o755)
        self.git("add", "-A")
        staged = self.digest("--staged")

        self.git("commit", "-qm", "replace file")
        commit = self.git("rev-parse", "HEAD").strip().decode()
        committed = self.digest("--committed", commit)

        self.assertEqual(staged["digest"], committed["digest"])
        self.assertEqual(staged["changes"], 2)

        added.chmod(0o644)
        self.git("add", "executable")
        mode_staged = self.digest("--staged")
        self.git("commit", "-qm", "change mode")
        mode_commit = self.git("rev-parse", "HEAD").strip().decode()
        mode_committed = self.digest("--committed", mode_commit)
        self.assertEqual(mode_staged["digest"], mode_committed["digest"])
        self.assertEqual(mode_staged["changes"], 1)

    def test_nested_path_matches_after_commit(self) -> None:
        nested = self.repo / "nested"
        nested.mkdir()
        (nested / "file").write_bytes(b"nested\x00content\n")
        self.git("add", "nested/file")
        staged = self.digest("--staged")

        self.git("commit", "-qm", "nested file")
        commit = self.git("rev-parse", "HEAD").strip().decode()
        committed = self.digest("--committed", commit)

        self.assertEqual(staged["digest"], committed["digest"])
        self.assertEqual(staged["changes"], 1)

    @unittest.skipUnless(os.name == "posix", "byte paths require POSIX")
    def test_non_utf8_path_matches_after_commit(self) -> None:
        path = os.fsencode(self.repo) + b"/byte-path-\xff"
        descriptor = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
        with os.fdopen(descriptor, "wb") as handle:
            handle.write(b"opaque path\n")
        subprocess.check_call(
            [b"git", b"add", b"--", b"byte-path-\xff"],
            cwd=os.fsencode(self.repo),
        )
        staged = self.digest("--staged")

        self.git("commit", "-qm", "byte path")
        commit = self.git("rev-parse", "HEAD").strip().decode()
        committed = self.digest("--committed", commit)

        self.assertEqual(staged["digest"], committed["digest"])

    def test_root_commit_is_supported(self) -> None:
        root = tempfile.TemporaryDirectory()
        try:
            repo = Path(root.name)
            subprocess.check_call(["git", "init", "-q"], cwd=repo)
            subprocess.check_call(["git", "config", "user.email", "test@example.invalid"], cwd=repo)
            subprocess.check_call(["git", "config", "user.name", "Digest Test"], cwd=repo)
            (repo / "root").write_bytes(b"root\x00\xff")
            subprocess.check_call(["git", "add", "root"], cwd=repo)
            subprocess.check_call(["git", "commit", "-qm", "root"], cwd=repo)
            commit = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=repo).strip().decode()
            result = json.loads(
                subprocess.check_output(
                    ["python3", str(SCRIPT), "--repo", str(repo), "--committed", commit],
                    cwd=repo,
                )
            )
            self.assertEqual(result["changes"], 1)
        finally:
            root.cleanup()

    def test_inherited_git_location_env_cannot_redirect_the_repo(self) -> None:
        other = tempfile.TemporaryDirectory()
        try:
            elsewhere = Path(other.name)
            init_repo(elsewhere)
            (elsewhere / "decoy").write_bytes(b"decoy\n")
            subprocess.check_call(["git", "add", "decoy"], cwd=elsewhere)
            subprocess.check_call(["git", "commit", "-qm", "decoy"], cwd=elsewhere)

            (self.repo / "before").write_bytes(b"staged change\n")
            self.git("add", "before")
            clean = self.digest("--staged")

            env = dict(os.environ)
            env["GIT_DIR"] = str(elsewhere / ".git")
            env["GIT_WORK_TREE"] = str(elsewhere)
            env["GIT_INDEX_FILE"] = str(elsewhere / ".git" / "index")
            env["GIT_OBJECT_DIRECTORY"] = str(elsewhere / ".git" / "objects")
            env["GIT_COMMON_DIR"] = str(elsewhere / ".git")
            env["GIT_ALTERNATE_OBJECT_DIRECTORIES"] = str(elsewhere / ".git" / "objects")
            redirected = self.digest("--staged", env=env)

            self.assertEqual(redirected["digest"], clean["digest"])
            self.assertEqual(redirected["changes"], 1)
        finally:
            other.cleanup()

    def test_worktree_matches_staged_and_committed(self) -> None:
        (self.repo / "before").write_bytes(b"changed\x00\xff\n")
        (self.repo / "added").write_bytes(b"added\x00\xff\n")
        work = self.digest("--worktree")
        explicit = self.digest("--worktree", "HEAD")

        self.git("add", "-A")
        staged = self.digest("--staged")
        self.git("commit", "-qm", "worktree candidate")
        commit = self.git("rev-parse", "HEAD").strip().decode()
        committed = self.digest("--committed", commit)

        self.assertEqual(work["mode"], "worktree")
        self.assertEqual(work["changes"], 2)
        self.assertEqual(work["digest"], explicit["digest"])
        self.assertEqual(work["digest"], staged["digest"])
        self.assertEqual(work["digest"], committed["digest"])

    def test_worktree_leaves_the_index_and_head_unchanged(self) -> None:
        (self.repo / "added").write_bytes(b"added\n")
        head = self.git("rev-parse", "HEAD")

        self.digest("--worktree")

        self.assertEqual(self.git("diff", "--cached", "--name-only"), b"")
        self.assertEqual(self.git("rev-parse", "HEAD"), head)
        self.assertIn(b"?? added", self.git("status", "--porcelain"))

    def test_every_mode_rejects_an_empty_delta(self) -> None:
        self.git("commit", "-qm", "empty", "--allow-empty")
        commit = self.git("rev-parse", "HEAD").strip().decode()
        for args in (["--staged"], ["--worktree"], ["--committed", commit]):
            with self.subTest(mode=args[0]):
                result = self.run_tool(*args)
                self.assertEqual(result.returncode, 4)
                self.assertEqual(result.stdout, b"")
                self.assertIn(
                    b"no changes were found for the selected mode",
                    result.stderr,
                )

    def test_unborn_head_digests_against_the_empty_tree(self) -> None:
        fresh = tempfile.TemporaryDirectory()
        try:
            repo = Path(fresh.name)
            init_repo(repo)
            (repo / "first").write_bytes(b"first\x00\xff\n")
            subprocess.check_call(["git", "add", "first"], cwd=repo)
            for mode in ("--staged", "--worktree"):
                with self.subTest(mode=mode):
                    result = subprocess.run(
                        ["python3", str(SCRIPT), "--repo", str(repo), mode],
                        capture_output=True,
                    )
                    self.assertEqual(result.returncode, 0, result.stderr)
                    self.assertEqual(json.loads(result.stdout)["changes"], 1)
        finally:
            fresh.cleanup()

    def test_git_failure_reports_a_clean_error(self) -> None:
        result = self.run_tool("--committed", "no-such-revision")

        self.assertEqual(result.returncode, 3)
        self.assertEqual(result.stdout, b"")
        self.assertIn(b"content-digest:", result.stderr)
        self.assertNotIn(b"usage:", result.stderr)


if __name__ == "__main__":
    unittest.main()
