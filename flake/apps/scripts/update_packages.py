#!/usr/bin/env python3
"""Update current-system local flake packages in independent commits."""

from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
from collections.abc import Sequence
from dataclasses import dataclass
from pathlib import Path

BRANCH_PACKAGES = {
    "codexbar-waybar",
    "codex-browser-use-linux-chromium",
    "colibri",
    "jj-hunk-tool",
    "lumen",
    "tokyonight-gtk-theme",
}

SKIP_PACKAGES = {
    "adv360-firmware": "source is managed by the adv360-zmk flake input",
    "avrogen": "nix-update cannot update buildDotnetGlobalTool version bindings",
    "bevy-brp-mcp": "the source update requires porting a local upstream patch",
    "cliproxyapi": "the source update also requires commit and build-date ldflags",
    "codexbar-cli": "four platform-specific release hashes require a custom updater",
    "playwright-cli": "the CLI update requires matching Chromium revision pins",
}

NIX_UPDATE_SUBJECT = re.compile(r"^(?P<package>[^:]+): (?P<old>.+) -> (?P<new>.+)$")


@dataclass(frozen=True)
class UpdateResult:
    package: str
    status: str
    detail: str
    log_path: Path | None = None


def run(
    command: Sequence[str],
    *,
    cwd: Path,
    env: dict[str, str] | None = None,
    check: bool = False,
) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        command,
        cwd=cwd,
        env=env,
        check=check,
        capture_output=True,
        text=True,
    )


def git(repo: Path, *args: str, check: bool = True) -> subprocess.CompletedProcess[str]:
    return run(("git", *args), cwd=repo, check=check)


def repository_root() -> Path:
    result = run(("git", "rev-parse", "--show-toplevel"), cwd=Path.cwd())
    if result.returncode != 0:
        raise RuntimeError("update-packages must run inside a Git repository")
    return Path(result.stdout.strip()).resolve()


def require_branch(repo: Path) -> None:
    branch = git(repo, "symbolic-ref", "--quiet", "--short", "HEAD", check=False)
    if branch.returncode != 0:
        raise RuntimeError("update-packages requires a checked-out branch")


def unstage_repository(repo: Path) -> None:
    git(repo, "restore", "--staged", ":/")


def current_system(repo: Path) -> str:
    result = run(
        ("nix", "eval", "--raw", "--impure", "--expr", "builtins.currentSystem"),
        cwd=repo,
        check=True,
    )
    return result.stdout.strip()


def flake_packages(repo: Path, system: str) -> list[str]:
    result = run(
        (
            "nix",
            "eval",
            "--json",
            f".#packages.{system}",
            "--apply",
            "builtins.attrNames",
        ),
        cwd=repo,
        check=True,
    )
    packages = json.loads(result.stdout)
    if not isinstance(packages, list) or not all(
        isinstance(item, str) for item in packages
    ):
        raise RuntimeError("flake package evaluation returned an unexpected value")
    return sorted(
        package
        for package in packages
        if (repo / "packages" / package / "package.nix").is_file()
    )


def package_path(repo: Path, package: str) -> Path:
    target = (repo / "packages" / package).resolve()
    packages_root = (repo / "packages").resolve()
    if target.parent != packages_root or not (target / "package.nix").is_file():
        raise RuntimeError(
            f"cannot map flake package {package!r} to packages/{package}"
        )
    return target


def target_changed(repo: Path, target: Path) -> bool:
    relative_target = str(target.relative_to(repo))
    status = git(
        repo,
        "status",
        "--porcelain",
        "--untracked-files=all",
        "--",
        relative_target,
    ).stdout
    return bool(status)


def rollback_failed_update(repo: Path, target: Path) -> None:
    relative_target = str(target.relative_to(repo))
    git(
        repo,
        "restore",
        "--source=HEAD",
        "--staged",
        "--worktree",
        "--",
        relative_target,
    )
    untracked = git(
        repo,
        "ls-files",
        "--others",
        "--exclude-standard",
        "-z",
        "--",
        relative_target,
    ).stdout.split("\0")
    for item in filter(None, untracked):
        path = (repo / item).resolve()
        if target not in path.parents and path != target:
            raise RuntimeError(f"refusing to remove unexpected path {path}")
        if path.is_dir():
            shutil.rmtree(path)
        else:
            path.unlink(missing_ok=True)


def discard_generated_commit(
    repo: Path, before: str, generated: str, target: Path
) -> None:
    current = git(repo, "rev-parse", "HEAD").stdout.strip()
    if current != generated:
        raise RuntimeError("cannot discard a generated commit after HEAD changed")
    git(repo, "update-ref", "HEAD", before, generated)
    unstage_repository(repo)
    rollback_failed_update(repo, target)


def parse_nix_update_subject(subject: str) -> tuple[str, str] | None:
    match = NIX_UPDATE_SUBJECT.fullmatch(subject)
    if not match:
        return None
    return match.group("old"), match.group("new")


def commit_is_scoped_to(repo: Path, commit: str, target: Path) -> bool:
    relative_target = str(target.relative_to(repo))
    paths = git(
        repo,
        "diff-tree",
        "--no-commit-id",
        "--name-only",
        "-r",
        "-z",
        commit,
    ).stdout.split("\0")
    prefix = f"{relative_target}/"
    return all(
        path == relative_target or path.startswith(prefix)
        for path in filter(None, paths)
    )


def commit_message(package: str, original_subject: str) -> tuple[str, str]:
    versions = parse_nix_update_subject(original_subject)
    if versions:
        old_version, new_version = versions
        candidate = f"chore({package}): update to {new_version}"
        subject = (
            candidate if len(candidate) <= 50 else f"chore(package): update {package}"
        )
        if len(subject) > 50:
            subject = "chore(packages): update local package"
        body = (
            f"Update {package} from {old_version} to {new_version}.\n\n"
            "nix-update built the package before creating this commit."
        )
    else:
        subject = f"chore({package}): update package"
        if len(subject) > 50:
            subject = "chore(packages): update local package"
        body = (
            f"Refresh {package} from its configured upstream.\n\n"
            "nix-update built the package before creating this commit."
        )
    return subject, body


def nix_update_environment() -> dict[str, str]:
    env = os.environ.copy()
    skipped_hooks = [item for item in env.get("SKIP", "").split(",") if item]
    if "technical-writing-commit-message" not in skipped_hooks:
        skipped_hooks.append("technical-writing-commit-message")
    env["SKIP"] = ",".join(skipped_hooks)
    return env


def update_package(repo: Path, package: str, log_dir: Path) -> UpdateResult:
    if reason := SKIP_PACKAGES.get(package):
        return UpdateResult(package, "skipped", reason)

    target = package_path(repo, package)
    if target_changed(repo, target):
        return UpdateResult(
            package, "skipped", "package directory has existing changes"
        )

    before = git(repo, "rev-parse", "HEAD").stdout.strip()
    command = ["nix-update", "--flake", "--build", "--commit"]
    if package in BRANCH_PACKAGES:
        command.extend(("--version", "branch"))
    command.append(package)

    result = run(command, cwd=repo, env=nix_update_environment())
    log_path = log_dir / f"{package}.log"
    log_path.write_text(result.stdout + result.stderr)

    if result.returncode != 0:
        rollback_failed_update(repo, target)
        return UpdateResult(
            package,
            "failed",
            f"nix-update exited with status {result.returncode}",
            log_path,
        )

    after = git(repo, "rev-parse", "HEAD").stdout.strip()
    if after == before:
        if target_changed(repo, target):
            rollback_failed_update(repo, target)
            return UpdateResult(
                package,
                "failed",
                "nix-update returned success without committing its changes",
                log_path,
            )
        return UpdateResult(package, "current", "no update available", log_path)

    parent = git(repo, "rev-parse", f"{after}^").stdout.strip()
    if parent != before:
        raise RuntimeError(f"{package} created an unexpected commit sequence")
    if not commit_is_scoped_to(repo, after, target):
        discard_generated_commit(repo, before, after, target)
        return UpdateResult(
            package,
            "failed",
            "nix-update committed changes outside the package directory",
            log_path,
        )

    original_subject = git(repo, "show", "-s", "--format=%s", after).stdout.strip()
    subject, body = commit_message(package, original_subject)
    git(repo, "restore", "--staged", ":/")
    amend = run(
        ("git", "commit", "--amend", "--message", subject, "--message", body),
        cwd=repo,
    )
    if amend.returncode != 0:
        log_path.write_text(
            log_path.read_text()
            + "\n--- commit amend ---\n"
            + amend.stdout
            + amend.stderr
        )
        discard_generated_commit(repo, before, after, target)
        return UpdateResult(
            package,
            "failed",
            "commit message amend failed",
            log_path,
        )

    committed = git(repo, "rev-parse", "HEAD").stdout.strip()
    return UpdateResult(package, "updated", committed[:12], log_path)


def parse_args(argv: Sequence[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Update current-system local flake packages in separate commits."
    )
    parser.add_argument(
        "packages", nargs="*", help="optional package attributes to update"
    )
    parser.add_argument(
        "--dry-run", action="store_true", help="list packages without updating"
    )
    return parser.parse_args(argv)


def print_summary(results: Sequence[UpdateResult], log_dir: Path) -> None:
    print("\nPackage update summary")
    print("=" * 22)
    for result in results:
        suffix = (
            f" ({result.log_path})"
            if result.log_path and result.status == "failed"
            else ""
        )
        print(f"{result.status:8} {result.package}: {result.detail}{suffix}")
    print(f"\nLogs: {log_dir}")


def main(argv: Sequence[str] | None = None) -> int:
    args = parse_args(argv if argv is not None else sys.argv[1:])
    try:
        repo = repository_root()
        require_branch(repo)
        system = current_system(repo)
        available = flake_packages(repo, system)
        requested = args.packages or available
        unknown = sorted(set(requested) - set(available))
        if unknown:
            raise RuntimeError(
                f"packages unavailable on {system}: {', '.join(unknown)}"
            )

        print(f"System: {system}")
        print(f"Packages: {len(requested)}")
        if args.dry_run:
            for package in requested:
                reason = SKIP_PACKAGES.get(package)
                print(f"{package}{f' (skip: {reason})' if reason else ''}")
            return 0

        unstage_repository(repo)
        log_dir = Path(tempfile.mkdtemp(prefix="update-packages-"))
        results: list[UpdateResult] = []
        for index, package in enumerate(requested, start=1):
            print(f"[{index}/{len(requested)}] {package}")
            results.append(update_package(repo, package, log_dir))

        print_summary(results, log_dir)
        return 1 if any(result.status == "failed" for result in results) else 0
    except (RuntimeError, subprocess.CalledProcessError) as error:
        print(f"update-packages: {error}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
