#!/usr/bin/env python3

import contextlib
import io
import json
import os
import stat
import subprocess
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

import update_container_digests as updater

OLD = "sha256:" + "a" * 64
NEW = "sha256:" + "b" * 64
SOURCE = (
    f'        web = "ghcr.io/example/web@{OLD}"; # keep this comment\r\n'
    f'        worker = "registry.example:5000/team/worker:v2@{OLD}";\r\n'
).encode()


def inspection(digest=NEW, architecture="amd64"):
    metadata = {"Os": "linux", "Architecture": architecture, "Digest": digest}
    return subprocess.CompletedProcess([], 0, json.dumps(metadata), "")


class UpdateContainerDigestsTests(unittest.TestCase):
    def setUp(self):
        cache = Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache"))
        cache.mkdir(parents=True, exist_ok=True)
        scratch = self.enterContext(tempfile.TemporaryDirectory(dir=cache))
        self.path = Path(scratch).resolve() / "images.nix"
        self.path.write_bytes(SOURCE)
        self.path.chmod(0o640)
        self.enterContext(
            patch.object(updater, "tracked_images_file", return_value=self.path)
        )
        self.skopeo = self.enterContext(
            patch.object(updater.subprocess, "run", return_value=inspection())
        )
        self.stdout = self.enterContext(contextlib.redirect_stdout(io.StringIO()))
        self.stderr = self.enterContext(contextlib.redirect_stderr(io.StringIO()))

    def test_check_reports_drift_without_rewriting(self):
        inode = self.path.stat().st_ino
        self.assertEqual(updater.main(["--check", "web", "--tag", "stable"]), 1)
        self.assertIn(f"{OLD} -> {NEW}", self.stdout.getvalue())
        self.assertEqual(self.path.read_bytes(), SOURCE)
        self.assertEqual(self.path.stat().st_ino, inode)
        self.skopeo.assert_called_once_with(
            [
                "skopeo",
                "--override-os",
                "linux",
                "--override-arch",
                "amd64",
                "inspect",
                "--no-tags",
                "docker://ghcr.io/example/web:stable",
            ],
            capture_output=True,
            text=True,
            check=True,
            timeout=60,
        )

    def test_check_uses_existing_tag_even_with_a_registry_port(self):
        self.skopeo.return_value = inspection(OLD)
        self.assertEqual(updater.main(["worker"]), 0)
        self.assertEqual(
            self.skopeo.call_args.args[0][-1],
            "docker://registry.example:5000/team/worker:v2",
        )
        self.assertIn(f"matches {OLD}", self.stdout.getvalue())
        self.assertEqual(self.path.read_bytes(), SOURCE)

    def test_update_rewrites_only_selected_digest_and_preserves_mode(self):
        self.assertEqual(updater.main(["--update", "web", "--tag", "stable"]), 0)
        self.assertEqual(
            self.path.read_bytes(), SOURCE.replace(OLD.encode(), NEW.encode(), 1)
        )
        self.assertEqual(stat.S_IMODE(self.path.stat().st_mode), 0o640)
        self.assertEqual(list(self.path.parent.iterdir()), [self.path])

    def test_update_is_a_noop_when_already_current(self):
        self.skopeo.return_value = inspection(OLD)
        inode = self.path.stat().st_ino
        self.assertEqual(updater.main(["--update", "worker"]), 0)
        self.assertEqual(self.path.read_bytes(), SOURCE)
        self.assertEqual(self.path.stat().st_ino, inode)

    def test_refuses_to_guess_or_change_a_tag(self):
        for args in (
            ["web"],
            ["worker", "--tag", "latest"],
            ["web", "--tag", "owner/other"],
        ):
            with self.subTest(args=args):
                self.assertEqual(updater.main(["--update", *args]), 2)
        self.skopeo.assert_not_called()
        self.assertEqual(self.path.read_bytes(), SOURCE)

    def test_unknown_duplicate_and_malformed_pins_fail_before_lookup(self):
        for contents in (b"", SOURCE * 2, SOURCE.replace(OLD.encode(), b"invalid", 1)):
            with self.subTest(contents=contents):
                self.path.write_bytes(contents)
                self.assertEqual(
                    updater.main(["--update", "web", "--tag", "stable"]), 2
                )
                self.assertEqual(self.path.read_bytes(), contents)
        self.skopeo.assert_not_called()

    def test_invalid_registry_responses_do_not_write(self):
        for result in (
            inspection("sha256:short"),
            inspection(architecture="arm64"),
            subprocess.CompletedProcess([], 0, "not JSON", ""),
        ):
            with self.subTest(result=result):
                self.skopeo.return_value = result
                self.assertEqual(updater.main(["--update", "worker"]), 2)
                self.assertEqual(self.path.read_bytes(), SOURCE)

    def test_registry_failure_does_not_write(self):
        self.skopeo.side_effect = subprocess.CalledProcessError(
            1, "skopeo", stderr="manifest unknown"
        )
        self.assertEqual(updater.main(["--update", "worker"]), 2)
        self.assertIn("manifest unknown", self.stderr.getvalue())
        self.assertEqual(self.path.read_bytes(), SOURCE)

    def test_update_preserves_edits_made_during_lookup(self):
        edited = SOURCE + b"# concurrent edit\n"

        def inspect(*args, **kwargs):
            self.path.write_bytes(edited)
            return inspection()

        self.skopeo.side_effect = inspect
        self.assertEqual(updater.main(["--update", "worker"]), 2)
        self.assertIn("changed during the lookup", self.stderr.getvalue())
        self.assertEqual(self.path.read_bytes(), edited)
        self.assertEqual(list(self.path.parent.iterdir()), [self.path])


if __name__ == "__main__":
    unittest.main()
