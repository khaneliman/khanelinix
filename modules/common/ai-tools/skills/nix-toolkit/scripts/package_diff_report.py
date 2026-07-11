#!/usr/bin/env python3
"""Build and compare two Nix installables without linking into the checkout."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import shutil
import stat
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import Any, Callable, ContextManager, Sequence

SCHEMA_VERSION = 1
DEFAULT_MAX_ITEMS = 50
DEFAULT_DIFFOSCOPE_LINES = 80
STORE_HASH_PATTERN = re.compile(r"/nix/store/[a-z0-9]{32}-")


class PackageDiffError(RuntimeError):
    """Raised when a package comparison cannot produce a trustworthy report."""


CommandRunner = Callable[
    [Sequence[str], Path, bool], subprocess.CompletedProcess[bytes]
]
TemporaryDirectoryFactory = Callable[..., ContextManager[str]]


def decode(value: bytes) -> str:
    return value.decode("utf-8", errors="surrogateescape")


def run_command(
    arguments: Sequence[str],
    cwd: Path,
    check: bool = True,
) -> subprocess.CompletedProcess[bytes]:
    environment = os.environ.copy()
    environment.update({"LC_ALL": "C"})
    try:
        result = subprocess.run(
            list(arguments),
            cwd=cwd,
            check=False,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            env=environment,
        )
    except OSError as error:
        raise PackageDiffError(f"could not run {arguments[0]}: {error}") from error

    if check and result.returncode != 0:
        detail = decode(result.stderr).strip() or "command failed without diagnostics"
        raise PackageDiffError(f"{' '.join(arguments)} failed: {detail}")
    return result


def resolve_repository(repository: Path) -> Path:
    try:
        return repository.resolve(strict=True)
    except OSError as error:
        raise PackageDiffError(f"repository path is unavailable: {error}") from error


def build_installable(
    runner: CommandRunner,
    repository: Path,
    installable: str,
) -> list[Path]:
    result = runner(
        [
            "nix",
            "build",
            "--no-link",
            "--print-out-paths",
            "--no-update-lock-file",
            "--no-write-lock-file",
            "--",
            installable,
        ],
        repository,
        True,
    )
    outputs: list[Path] = []
    seen_outputs: set[Path] = set()
    for line in decode(result.stdout).splitlines():
        if not line.strip():
            continue
        output = Path(line)
        if output not in seen_outputs:
            outputs.append(output)
            seen_outputs.add(output)
    if not outputs:
        raise PackageDiffError(f"{installable} produced no output paths")
    missing = [str(path) for path in outputs if not path.exists()]
    if missing:
        raise PackageDiffError(
            f"{installable} returned missing output path(s): {', '.join(missing)}"
        )
    return outputs


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def path_metadata(path: Path, hash_files: bool) -> dict[str, Any]:
    info = path.lstat()
    mode = f"{stat.S_IMODE(info.st_mode):04o}"
    if stat.S_ISLNK(info.st_mode):
        return {"kind": "symlink", "mode": mode, "target": os.readlink(path)}
    if stat.S_ISDIR(info.st_mode):
        return {"kind": "directory", "mode": mode}
    if stat.S_ISREG(info.st_mode):
        metadata: dict[str, Any] = {
            "kind": "file",
            "mode": mode,
            "size_bytes": info.st_size,
        }
        if hash_files:
            metadata["sha256"] = sha256_file(path)
        return metadata
    return {"kind": "other", "mode": mode, "size_bytes": info.st_size}


def output_manifest(outputs: Sequence[Path], hash_files: bool) -> dict[str, Any]:
    manifest: dict[str, Any] = {}
    for output_index, output in enumerate(outputs):
        prefix = f"output[{output_index}]"
        manifest[prefix] = path_metadata(output, hash_files)
        if not output.is_dir():
            continue

        for current_root, directory_names, file_names in os.walk(
            output, topdown=True, followlinks=False
        ):
            directory_names.sort()
            file_names.sort()
            current = Path(current_root)

            traversable_directories: list[str] = []
            for name in directory_names:
                path = current / name
                relative = path.relative_to(output).as_posix()
                manifest[f"{prefix}/{relative}"] = path_metadata(path, hash_files)
                if not path.is_symlink():
                    traversable_directories.append(name)
            directory_names[:] = traversable_directories

            for name in file_names:
                path = current / name
                relative = path.relative_to(output).as_posix()
                manifest[f"{prefix}/{relative}"] = path_metadata(path, hash_files)
    return dict(sorted(manifest.items()))


def bounded(items: Sequence[Any], maximum: int) -> dict[str, Any]:
    if maximum < 0:
        raise PackageDiffError("maximum report items must be zero or greater")
    selected = list(items if maximum == 0 else items[:maximum])
    return {
        "count": len(items),
        "items": selected,
        "omitted": len(items) - len(selected),
    }


def compare_manifests(
    before: dict[str, Any],
    after: dict[str, Any],
    maximum: int,
) -> dict[str, Any]:
    before_paths = set(before)
    after_paths = set(after)
    added = sorted(after_paths - before_paths)
    removed = sorted(before_paths - after_paths)
    changed = [
        {"after": after[path], "before": before[path], "path": path}
        for path in sorted(before_paths & after_paths)
        if before[path] != after[path]
    ]
    return {
        "added": bounded(added, maximum),
        "after_entries": len(after),
        "before_entries": len(before),
        "changed": bounded(changed, maximum),
        "removed": bounded(removed, maximum),
    }


def collect_closure(
    runner: CommandRunner,
    repository: Path,
    outputs: Sequence[Path],
) -> dict[str, Any]:
    result = runner(
        [
            "nix",
            "path-info",
            "--json",
            "--json-format",
            "1",
            "--recursive",
            "--closure-size",
            *(str(path) for path in outputs),
        ],
        repository,
        True,
    )
    try:
        data = json.loads(decode(result.stdout))
    except json.JSONDecodeError as error:
        raise PackageDiffError(
            f"nix path-info returned invalid JSON: {error}"
        ) from error
    if not isinstance(data, dict):
        raise PackageDiffError("nix path-info JSON must be an object")

    paths = sorted(data)
    nar_size = sum(
        value.get("narSize", 0)
        for value in data.values()
        if isinstance(value, dict) and isinstance(value.get("narSize", 0), int)
    )
    return {"nar_size_bytes": nar_size, "paths": paths}


def compare_closures(
    before: dict[str, Any],
    after: dict[str, Any],
    maximum: int,
) -> dict[str, Any]:
    before_paths = set(before["paths"])
    after_paths = set(after["paths"])
    return {
        "added": bounded(sorted(after_paths - before_paths), maximum),
        "after_nar_size_bytes": after["nar_size_bytes"],
        "after_paths": len(after_paths),
        "before_nar_size_bytes": before["nar_size_bytes"],
        "before_paths": len(before_paths),
        "nar_size_delta_bytes": after["nar_size_bytes"] - before["nar_size_bytes"],
        "removed": bounded(sorted(before_paths - after_paths), maximum),
    }


def normalize_diffoscope(text: str, temporary_root: Path) -> str:
    normalized = text.replace(str(temporary_root), "<temporary>")
    return STORE_HASH_PATTERN.sub("/nix/store/<hash>-", normalized)


def run_diffoscope(
    runner: CommandRunner,
    repository: Path,
    executable: str,
    before_outputs: Sequence[Path],
    after_outputs: Sequence[Path],
    temporary_root: Path,
    maximum_lines: int,
) -> dict[str, Any]:
    if maximum_lines < 0:
        raise PackageDiffError("diffoscope lines must be zero or greater")

    comparisons: list[dict[str, Any]] = []
    for index, (before, after) in enumerate(zip(before_outputs, after_outputs)):
        report_path = temporary_root / f"diffoscope-{index}.txt"
        result = runner(
            [executable, "--text", str(report_path), str(before), str(after)],
            repository,
            False,
        )
        if result.returncode not in {0, 1}:
            detail = decode(result.stderr).strip() or "diffoscope failed"
            raise PackageDiffError(detail)
        if not report_path.exists():
            raise PackageDiffError("diffoscope did not create its requested report")

        report_text = report_path.read_text(encoding="utf-8", errors="surrogateescape")
        report_lines = normalize_diffoscope(report_text, temporary_root).splitlines()
        selected_lines = (
            report_lines if maximum_lines == 0 else report_lines[:maximum_lines]
        )
        comparisons.append(
            {
                "after_output": str(after),
                "before_output": str(before),
                "different": result.returncode == 1,
                "excerpt": selected_lines,
                "excerpt_lines_omitted": len(report_lines) - len(selected_lines),
                "output_index": index,
            }
        )

    return {
        "comparisons": comparisons,
        "output_count_mismatch": len(before_outputs) != len(after_outputs),
        "requested": True,
    }


def build_report(
    repository: Path,
    before_installable: str,
    after_installable: str,
    *,
    hash_files: bool = True,
    maximum_items: int = DEFAULT_MAX_ITEMS,
    diffoscope: bool = False,
    diffoscope_lines: int = DEFAULT_DIFFOSCOPE_LINES,
    runner: CommandRunner | None = None,
    temporary_directory: TemporaryDirectoryFactory = tempfile.TemporaryDirectory,
    which: Callable[[str], str | None] = shutil.which,
) -> dict[str, Any]:
    command_runner = runner or run_command
    root = resolve_repository(repository)
    before_outputs = build_installable(command_runner, root, before_installable)
    after_outputs = build_installable(command_runner, root, after_installable)

    before_manifest = output_manifest(before_outputs, hash_files)
    after_manifest = output_manifest(after_outputs, hash_files)
    before_closure = collect_closure(command_runner, root, before_outputs)
    after_closure = collect_closure(command_runner, root, after_outputs)

    diffoscope_report: dict[str, Any] = {"requested": False}
    if diffoscope:
        executable = which("diffoscope")
        if executable is None:
            raise PackageDiffError("diffoscope was requested but is not on PATH")
        with temporary_directory(prefix="nix-package-diff-") as temporary_root:
            diffoscope_report = run_diffoscope(
                command_runner,
                root,
                executable,
                before_outputs,
                after_outputs,
                Path(temporary_root),
                diffoscope_lines,
            )

    return {
        "after": {
            "input": after_installable,
            "outputs": [str(path) for path in after_outputs],
        },
        "before": {
            "input": before_installable,
            "outputs": [str(path) for path in before_outputs],
        },
        "closure": compare_closures(before_closure, after_closure, maximum_items),
        "diffoscope": diffoscope_report,
        "file_hashes": hash_files,
        "files": compare_manifests(before_manifest, after_manifest, maximum_items),
        "repository": str(root),
        "schema_version": SCHEMA_VERSION,
    }


def render_text(report: dict[str, Any]) -> str:
    files = report["files"]
    closure = report["closure"]
    lines = [
        f"repository: {report['repository']}",
        f"before: {report['before']['input']}",
        f"after: {report['after']['input']}",
        (
            "files: "
            f"+{files['added']['count']} "
            f"-{files['removed']['count']} "
            f"~{files['changed']['count']}"
        ),
        (
            "closure: "
            f"+{closure['added']['count']} "
            f"-{closure['removed']['count']} "
            f"({closure['nar_size_delta_bytes']:+d} bytes)"
        ),
    ]
    for category in ("added", "removed", "changed"):
        for item in files[category]["items"]:
            path = item["path"] if isinstance(item, dict) else item
            lines.append(f"  {category}: {path}")
        if files[category]["omitted"]:
            lines.append(f"  {category}: {files[category]['omitted']} more omitted")
    if report["diffoscope"]["requested"]:
        different = sum(
            comparison["different"]
            for comparison in report["diffoscope"]["comparisons"]
        )
        lines.append(
            "diffoscope: "
            f"{different}/{len(report['diffoscope']['comparisons'])} "
            "output pair(s) differ"
        )
    return "\n".join(lines) + "\n"


def parse_arguments(argv: Sequence[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Build two Nix installables without result links or lock-file "
            "updates, then report file and closure differences."
        )
    )
    parser.add_argument("--repo", type=Path, default=Path.cwd())
    parser.add_argument("--before", required=True, help="comparison installable")
    parser.add_argument("--after", required=True, help="candidate installable")
    parser.add_argument(
        "--no-file-hashes",
        action="store_true",
        help="compare file metadata without hashing regular-file contents",
    )
    parser.add_argument(
        "--max-items",
        type=int,
        default=DEFAULT_MAX_ITEMS,
        help="maximum items per report list; 0 means unlimited (default: 50)",
    )
    parser.add_argument(
        "--diffoscope",
        action="store_true",
        help="run diffoscope when it is available on PATH",
    )
    parser.add_argument(
        "--diffoscope-lines",
        type=int,
        default=DEFAULT_DIFFOSCOPE_LINES,
        help="maximum excerpt lines per output pair; 0 means unlimited",
    )
    parser.add_argument(
        "--format", choices=("json", "text"), default="json", help="output format"
    )
    return parser.parse_args(argv)


def main(argv: Sequence[str] | None = None) -> int:
    arguments = parse_arguments(argv)
    try:
        report = build_report(
            arguments.repo,
            arguments.before,
            arguments.after,
            hash_files=not arguments.no_file_hashes,
            maximum_items=arguments.max_items,
            diffoscope=arguments.diffoscope,
            diffoscope_lines=arguments.diffoscope_lines,
        )
    except PackageDiffError as error:
        print(f"error: {error}", file=sys.stderr)
        return 1

    if arguments.format == "json":
        print(json.dumps(report, indent=2, sort_keys=True, ensure_ascii=False))
    else:
        sys.stdout.write(render_text(report))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
