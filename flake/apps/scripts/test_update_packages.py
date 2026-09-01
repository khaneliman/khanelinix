#!/usr/bin/env python3

import importlib.util
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

SCRIPT = Path(__file__).with_name("update_packages.py")
SPEC = importlib.util.spec_from_file_location("update_packages", SCRIPT)
assert SPEC and SPEC.loader
update_packages = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = update_packages
SPEC.loader.exec_module(update_packages)


class UpdatePackagesTests(unittest.TestCase):
    def init_repository(self, root: Path) -> Path:
        subprocess.run(("git", "init", "--quiet"), cwd=root, check=True)
        subprocess.run(
            ("git", "config", "user.name", "Updater Test"), cwd=root, check=True
        )
        subprocess.run(
            ("git", "config", "user.email", "updater@example.invalid"),
            cwd=root,
            check=True,
        )
        target = root / "packages" / "example"
        target.mkdir(parents=True)
        (target / "package.nix").write_text("version = old;\n")
        (root / "marker.txt").write_text("before\n")
        subprocess.run(("git", "add", ":/"), cwd=root, check=True)
        subprocess.run(
            ("git", "commit", "--quiet", "-m", "test: baseline"),
            cwd=root,
            check=True,
        )
        return target

    def test_parse_nix_update_subject(self) -> None:
        self.assertEqual(
            ("0.1.13", "0.1.19"),
            update_packages.parse_nix_update_subject(
                "playwright-cli: 0.1.13 -> 0.1.19"
            ),
        )

    def test_reject_unexpected_subject(self) -> None:
        self.assertIsNone(update_packages.parse_nix_update_subject("not an update"))

    def test_commit_message_uses_repository_format(self) -> None:
        subject, body = update_packages.commit_message(
            "playwright-cli", "playwright-cli: 0.1.13 -> 0.1.19"
        )
        self.assertEqual("chore(playwright-cli): update to 0.1.19", subject)
        self.assertLessEqual(len(subject), 50)
        self.assertIn("0.1.13", body)
        self.assertIn("0.1.19", body)

    def test_long_package_name_keeps_subject_bounded(self) -> None:
        subject, _ = update_packages.commit_message(
            "codex-browser-use-linux-chromium",
            "codex-browser-use-linux-chromium: 1 -> 2",
        )
        self.assertLessEqual(len(subject), 50)

    def test_coupled_packages_are_explicitly_skipped(self) -> None:
        for package in (
            "bevy-brp-mcp",
            "cliproxyapi",
            "codexbar-cli",
            "playwright-cli",
        ):
            self.assertIn(package, update_packages.SKIP_PACKAGES)

    def test_dry_run_does_not_unstage_repository(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            repo = Path(temp_dir)
            with (
                patch.object(update_packages, "repository_root", return_value=repo),
                patch.object(update_packages, "require_branch"),
                patch.object(
                    update_packages, "current_system", return_value="test-system"
                ),
                patch.object(
                    update_packages, "flake_packages", return_value=["berrycode"]
                ),
                patch.object(update_packages, "unstage_repository") as unstage,
            ):
                self.assertEqual(0, update_packages.main(["--dry-run"]))
                unstage.assert_not_called()

    def test_out_of_scope_commit_is_discarded(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            repo = Path(temp_dir)
            target = self.init_repository(repo)
            before = subprocess.run(
                ("git", "rev-parse", "HEAD"),
                cwd=repo,
                check=True,
                capture_output=True,
                text=True,
            ).stdout.strip()
            original_run = update_packages.run

            def simulate_nix_update(command, **kwargs):
                if command[0] != "nix-update":
                    return original_run(command, **kwargs)
                (target / "package.nix").write_text("version = new;\n")
                (repo / "marker.txt").write_text("after\n")
                subprocess.run(("git", "add", ":/"), cwd=repo, check=True)
                subprocess.run(
                    ("git", "commit", "--quiet", "-m", "example: old -> new"),
                    cwd=repo,
                    check=True,
                )
                return subprocess.CompletedProcess(command, 0, "", "")

            with (
                tempfile.TemporaryDirectory() as log_dir,
                patch.object(update_packages, "run", side_effect=simulate_nix_update),
            ):
                result = update_packages.update_package(repo, "example", Path(log_dir))

            self.assertEqual("failed", result.status)
            self.assertEqual(
                before,
                subprocess.run(
                    ("git", "rev-parse", "HEAD"),
                    cwd=repo,
                    check=True,
                    capture_output=True,
                    text=True,
                ).stdout.strip(),
            )
            self.assertEqual("version = old;\n", (target / "package.nix").read_text())
            self.assertEqual("after\n", (repo / "marker.txt").read_text())

    def test_amend_failure_discards_package_commit(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            repo = Path(temp_dir)
            target = self.init_repository(repo)
            before = subprocess.run(
                ("git", "rev-parse", "HEAD"),
                cwd=repo,
                check=True,
                capture_output=True,
                text=True,
            ).stdout.strip()
            original_run = update_packages.run

            def simulate_amend_failure(command, **kwargs):
                if command[0] == "nix-update":
                    (target / "package.nix").write_text("version = new;\n")
                    subprocess.run(("git", "add", ":/"), cwd=repo, check=True)
                    subprocess.run(
                        (
                            "git",
                            "commit",
                            "--quiet",
                            "-m",
                            "example: old -> new",
                        ),
                        cwd=repo,
                        check=True,
                    )
                    return subprocess.CompletedProcess(command, 0, "", "")
                if command[:3] == ("git", "commit", "--amend"):
                    return subprocess.CompletedProcess(command, 1, "", "hook failed")
                return original_run(command, **kwargs)

            with (
                tempfile.TemporaryDirectory() as log_dir,
                patch.object(
                    update_packages, "run", side_effect=simulate_amend_failure
                ),
            ):
                result = update_packages.update_package(repo, "example", Path(log_dir))

            self.assertEqual("failed", result.status)
            self.assertEqual(
                before,
                subprocess.run(
                    ("git", "rev-parse", "HEAD"),
                    cwd=repo,
                    check=True,
                    capture_output=True,
                    text=True,
                ).stdout.strip(),
            )
            self.assertEqual("version = old;\n", (target / "package.nix").read_text())

    def test_batch_continues_after_package_failure(self) -> None:
        failed = update_packages.UpdateResult("first", "failed", "test failure")
        current = update_packages.UpdateResult("second", "current", "no update")
        with tempfile.TemporaryDirectory() as temp_dir:
            repo = Path(temp_dir)
            with (
                patch.object(update_packages, "repository_root", return_value=repo),
                patch.object(update_packages, "require_branch"),
                patch.object(
                    update_packages, "current_system", return_value="test-system"
                ),
                patch.object(
                    update_packages,
                    "flake_packages",
                    return_value=["first", "second"],
                ),
                patch.object(update_packages, "unstage_repository"),
                patch.object(
                    update_packages,
                    "update_package",
                    side_effect=[failed, current],
                ) as update,
            ):
                self.assertEqual(1, update_packages.main([]))
                self.assertEqual(2, update.call_count)


if __name__ == "__main__":
    unittest.main()
