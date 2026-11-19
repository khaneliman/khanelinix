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
        self.assertNotIn("nix-update", body)

    def test_long_package_name_keeps_subject_bounded(self) -> None:
        subject, body = update_packages.commit_message(
            "codex-browser-use-linux-chromium",
            "codex-browser-use-linux-chromium: 0.1.0-unstable-2026-06-24 -> 0-unstable-2026-06-24",
        )
        self.assertLessEqual(len(subject), 50)
        self.assertTrue(all(len(line) <= 72 for line in body.splitlines()))

    def test_coupled_packages_are_explicitly_skipped(self) -> None:
        for package in (
            "bevy-brp-mcp",
            "cliproxyapi",
            "codexbar-cli",
            "playwright-cli",
        ):
            self.assertIn(package, update_packages.SKIP_PACKAGES)

    def test_blender_uses_release_tag_filter(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            repo = Path(temp_dir)
            target = self.init_repository(repo)
            target.rename(target.parent / "blender-mcp")
            subprocess.run(("git", "add", ":/"), cwd=repo, check=True)
            subprocess.run(
                ("git", "commit", "--quiet", "-m", "test: rename package"),
                cwd=repo,
                check=True,
            )
            original_run = update_packages.run
            commands = []

            def simulate_nix_update(command, **kwargs):
                if command[0] == "nix-update":
                    commands.append(command)
                    return subprocess.CompletedProcess(command, 0, "", "")
                return original_run(command, **kwargs)

            with patch.object(update_packages, "run", side_effect=simulate_nix_update):
                result = update_packages.update_package(repo, "blender-mcp", repo)
            self.assertEqual("current", result.status)
            self.assertEqual(1, len(commands))
            command = commands[0]
            self.assertEqual(
                r"^v([0-9]+\.[0-9]+\.[0-9]+)$",
                command[command.index("--version-regex") + 1],
            )

    def test_null_update_script_packages_are_excluded(self) -> None:
        self.assertIn(
            "updateScript or true) != null",
            update_packages.UPDATABLE_PACKAGES_FILTER,
        )

    def test_dry_run_does_not_unstage_repository(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            repo = Path(temp_dir)
            self.init_repository(repo)
            marker = repo / "marker.txt"
            marker.write_text("staged\n")
            update_packages.git(repo, "add", "marker.txt")
            with (
                patch.object(update_packages, "repository_root", return_value=repo),
                patch.object(
                    update_packages, "current_system", return_value="test-system"
                ),
                patch.object(
                    update_packages, "flake_packages", return_value=["berrycode"]
                ),
            ):
                self.assertEqual(0, update_packages.main(["--dry-run"]))
            self.assertEqual(
                "staged\n", update_packages.git(repo, "show", ":marker.txt").stdout
            )

    def test_skips_package_with_existing_changes(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            repo = Path(temp_dir)
            target = self.init_repository(repo)
            package_file = target / "package.nix"
            package_file.write_text("version = staged;\n")
            update_packages.git(repo, "add", str(package_file))
            package_file.write_text("version = unstaged;\n")

            with patch.object(update_packages, "prepare_update") as update:
                result = update_packages.update_package(repo, "example", repo)

            self.assertEqual("skipped", result.status)
            update.assert_not_called()
            self.assertEqual("version = unstaged;\n", package_file.read_text())
            self.assertEqual(
                "version = staged;\n",
                update_packages.git(
                    repo, "show", ":packages/example/package.nix"
                ).stdout,
            )

    def test_update_preserves_unrelated_work(self) -> None:
        for outcome in ("success", "failure", "failure after commit", "no commit"):
            with self.subTest(outcome=outcome):
                self.assert_update_preserves_unrelated_work(outcome)

    def assert_update_preserves_unrelated_work(self, outcome: str) -> None:
        temp_dir = self.enterContext(tempfile.TemporaryDirectory())
        repo = Path(temp_dir)
        target = self.init_repository(repo)
        before = update_packages.git(repo, "rev-parse", "HEAD").stdout
        marker = repo / "marker.txt"
        marker.write_text("staged\n")
        update_packages.git(repo, "add", "marker.txt")
        marker.write_text("unstaged\n")
        original_run = update_packages.run

        def simulate_nix_update(command, **kwargs):
            if command[0] != "nix-update":
                return original_run(command, **kwargs)
            checkout = kwargs["cwd"]
            scratch_target = checkout / target.relative_to(repo)
            (scratch_target / "package.nix").write_text("version = new;\n")
            env = kwargs["env"]
            if outcome in ("success", "failure after commit"):
                update_packages.git(
                    checkout,
                    "commit",
                    "-qm",
                    "example: old -> new",
                    "--",
                    "packages/example",
                    env=env,
                )
            if outcome != "success":
                (scratch_target / "generated").symlink_to(checkout / "marker.txt")
            (checkout / "marker.txt").write_text("extraneous overwrite\n")
            (checkout / "extraneous.txt").write_text("new file\n")
            update_packages.git(checkout, "add", ":/", env=env)
            code = int(outcome.startswith("failure"))
            return subprocess.CompletedProcess(command, code, "", "")

        with (
            patch.dict("os.environ", {"GIT_INDEX_FILE": str(repo / ".git/index")}),
            patch.object(update_packages, "run", side_effect=simulate_nix_update),
        ):
            result = update_packages.update_package(repo, "example", repo)

        self.assertEqual("unstaged\n", marker.read_text())
        self.assertFalse((repo / "extraneous.txt").exists())
        self.assertEqual(
            1, update_packages.git(repo, "worktree", "list").stdout.count("\n")
        )
        self.assertEqual(
            "staged\n", update_packages.git(repo, "show", ":marker.txt").stdout
        )
        self.assertFalse(update_packages.target_changed(repo, target))
        head = update_packages.git(repo, "rev-parse", "HEAD").stdout
        if outcome == "success":
            self.assertEqual("updated", result.status)
            self.assertNotEqual(before, head)
            self.assertEqual(
                "chore(example): update to new\n",
                update_packages.git(repo, "show", "-s", "--format=%s").stdout,
            )
            self.assertEqual(
                "before\n",
                update_packages.git(repo, "show", "HEAD:marker.txt").stdout,
            )
        else:
            self.assertEqual("failed", result.status)
            self.assertEqual(before, head)
            self.assertEqual("version = old;\n", (target / "package.nix").read_text())

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
                checkout = kwargs["cwd"]
                (checkout / target.relative_to(repo) / "package.nix").write_text(
                    "version = new;\n"
                )
                (checkout / "marker.txt").write_text("after\n")
                subprocess.run(
                    ("git", "add", ":/"), cwd=checkout, env=kwargs["env"], check=True
                )
                subprocess.run(
                    ("git", "commit", "--quiet", "-m", "example: old -> new"),
                    cwd=checkout,
                    env=kwargs["env"],
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
            self.assertEqual("before\n", (repo / "marker.txt").read_text())
            self.assertEqual(
                "before\n", update_packages.git(repo, "show", ":marker.txt").stdout
            )

    def test_concurrent_commit_is_not_rewound(self) -> None:
        for exit_status in (0, 1):
            with self.subTest(exit_status=exit_status):
                self.assert_concurrent_commit_survives(exit_status)

    def assert_concurrent_commit_survives(self, exit_status: int) -> None:
        repo = Path(self.enterContext(tempfile.TemporaryDirectory()))
        target = self.init_repository(repo)
        marker = repo / "marker.txt"
        marker.write_text("staged\n")
        update_packages.git(repo, "add", "marker.txt")
        marker.write_text("unstaged\n")
        original_run = update_packages.run

        def simulate_nix_update(command, **kwargs):
            if command[0] != "nix-update":
                return original_run(command, **kwargs)
            checkout = kwargs["cwd"]
            (checkout / target.relative_to(repo) / "package.nix").write_text(
                "version = new;\n"
            )
            update_packages.git(
                checkout, "commit", "-qam", "example: old -> new", env=kwargs["env"]
            )
            (repo / "concurrent.txt").write_text("user content\n")
            update_packages.git(repo, "add", "concurrent.txt")
            update_packages.git(
                repo, "commit", "-qm", "user commit", "--", "concurrent.txt"
            )
            return subprocess.CompletedProcess(command, exit_status, "", "")

        with patch.object(update_packages, "run", side_effect=simulate_nix_update):
            result = update_packages.update_package(repo, "example", repo)

        self.assertEqual("failed", result.status)
        if not exit_status:
            self.assertIn("expected base", result.detail)
        self.assertEqual(
            "user commit\n",
            update_packages.git(repo, "show", "-s", "--format=%s").stdout,
        )
        self.assertEqual(
            "user content\n",
            update_packages.git(repo, "show", "HEAD:concurrent.txt").stdout,
        )
        self.assertEqual("version = old;\n", (target / "package.nix").read_text())
        self.assertEqual("unstaged\n", marker.read_text())
        self.assertEqual(
            "staged\n", update_packages.git(repo, "show", ":marker.txt").stdout
        )

    def test_apply_refuses_package_edit_during_handoff(self) -> None:
        repo = Path(self.enterContext(tempfile.TemporaryDirectory()))
        target = self.init_repository(repo)
        before = update_packages.git(repo, "rev-parse", "HEAD").stdout
        package_file = target / "package.nix"
        original_run = update_packages.run

        def simulate_update_and_local_edit(command, **kwargs):
            if command[0] == "nix-update":
                checkout = kwargs["cwd"]
                (checkout / package_file.relative_to(repo)).write_text(
                    "version = new;\n"
                )
                update_packages.git(
                    checkout, "commit", "-qam", "example: old -> new", env=kwargs["env"]
                )
                return subprocess.CompletedProcess(command, 0, "", "")
            if command[:2] == ("git", "read-tree"):
                package_file.write_text("version = local;\n")
            return original_run(command, **kwargs)

        with patch.object(
            update_packages, "run", side_effect=simulate_update_and_local_edit
        ):
            result = update_packages.update_package(repo, "example", repo)

        self.assertEqual("failed", result.status)
        self.assertIn("could not apply", result.detail)
        self.assertEqual(before, update_packages.git(repo, "rev-parse", "HEAD").stdout)
        self.assertEqual("version = local;\n", package_file.read_text())
        self.assertEqual("", update_packages.git(repo, "diff", "--cached").stdout)

    def test_amend_failure_discards_package_commit(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            repo = Path(temp_dir)
            target = self.init_repository(repo)
            marker = repo / "marker.txt"
            marker.write_text("staged\n")
            update_packages.git(repo, "add", "marker.txt")
            marker.write_text("unstaged\n")
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
                    checkout = kwargs["cwd"]
                    (checkout / target.relative_to(repo) / "package.nix").write_text(
                        "version = new;\n"
                    )
                    update_packages.git(
                        checkout,
                        "commit",
                        "-qm",
                        "example: old -> new",
                        "--",
                        "packages/example",
                        env=kwargs["env"],
                    )
                    return subprocess.CompletedProcess(command, 0, "", "")
                if command[:3] == ("git", "commit", "--amend"):
                    checkout = kwargs["cwd"]
                    (checkout / "marker.txt").write_text("hook overwrite\n")
                    update_packages.git(
                        checkout, "add", "marker.txt", env=kwargs["env"]
                    )
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
            self.assertEqual("unstaged\n", marker.read_text())
            self.assertEqual(
                "staged\n", update_packages.git(repo, "show", ":marker.txt").stdout
            )

    def test_branch_update_with_unchanged_revision_is_current(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            repo = Path(temp_dir)
            target = self.init_repository(repo)
            package_file = target / "package.nix"
            revision = "a" * 40
            package_file.write_text(f'version = "1";\nrev = "{revision}";\n')
            subprocess.run(("git", "add", ":/"), cwd=repo, check=True)
            subprocess.run(
                ("git", "commit", "--quiet", "-m", "test: add revision"),
                cwd=repo,
                check=True,
            )
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
                checkout = kwargs["cwd"]
                (checkout / package_file.relative_to(repo)).write_text(
                    f'version = "2";\nrev = "{revision}";\n'
                )
                subprocess.run(
                    ("git", "add", ":/"), cwd=checkout, env=kwargs["env"], check=True
                )
                subprocess.run(
                    ("git", "commit", "--quiet", "-m", "example: 1 -> 2"),
                    cwd=checkout,
                    env=kwargs["env"],
                    check=True,
                )
                return subprocess.CompletedProcess(command, 0, "", "")

            with (
                tempfile.TemporaryDirectory() as log_dir,
                patch.object(update_packages, "run", side_effect=simulate_nix_update),
                patch.object(update_packages, "BRANCH_PACKAGES", {"example"}),
            ):
                result = update_packages.update_package(repo, "example", Path(log_dir))

            self.assertEqual("current", result.status)
            self.assertEqual("upstream revision is unchanged", result.detail)
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
            self.assertEqual(
                f'version = "1";\nrev = "{revision}";\n', package_file.read_text()
            )

    def test_batch_continues_after_package_failure(self) -> None:
        failed = update_packages.UpdateResult("first", "failed", "test failure")
        current = update_packages.UpdateResult("second", "current", "no update")
        with tempfile.TemporaryDirectory() as temp_dir:
            repo = Path(temp_dir)
            self.init_repository(repo)
            (repo / "marker.txt").write_text("staged\n")
            update_packages.git(repo, "add", "marker.txt")
            with (
                patch.object(update_packages, "repository_root", return_value=repo),
                patch.object(
                    update_packages, "current_system", return_value="test-system"
                ),
                patch.object(
                    update_packages,
                    "flake_packages",
                    return_value=["first", "second"],
                ),
                patch.object(
                    update_packages,
                    "update_package",
                    side_effect=[failed, current],
                ) as update,
                patch.object(
                    update_packages.tempfile, "mkdtemp", return_value=temp_dir
                ),
            ):
                self.assertEqual(1, update_packages.main([]))
                self.assertEqual(2, update.call_count)
            self.assertEqual(
                "staged\n", update_packages.git(repo, "show", ":marker.txt").stdout
            )


if __name__ == "__main__":
    unittest.main()
