#!/usr/bin/env python3
"""Run nixpkgs-review against only actually changed vimPlugins attrs."""

from __future__ import annotations

import argparse
import json
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import Any

PLUGIN_ROOT = Path("pkgs/applications/editors/vim/plugins")
GENERATED = PLUGIN_ROOT / "generated.nix"
OVERRIDES = PLUGIN_ROOT / "overrides.nix"
PATCHES = PLUGIN_ROOT / "patches"


def run(
    argv: list[str],
    *,
    cwd: Path | None = None,
    check: bool = True,
    capture: bool = True,
) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        argv,
        cwd=cwd,
        check=check,
        text=True,
        stdout=subprocess.PIPE if capture else None,
        stderr=subprocess.PIPE if capture else None,
    )


def require_tool(name: str) -> None:
    if shutil.which(name) is None:
        raise SystemExit(f"missing required tool: {name}")


def parse_pr_number(value: str) -> str:
    match = re.search(r"/pull/([0-9]+)", value)
    if match:
        return match.group(1)
    if value.isdigit():
        return value
    raise SystemExit(f"cannot parse PR number from: {value}")


def pr_info(repo: str, pr: str) -> dict[str, Any]:
    fields = "baseRefName,baseRefOid,headRefOid,title,url"
    result = run(["gh", "pr", "view", pr, "--repo", repo, "--json", fields])
    return json.loads(result.stdout)


def git(cwd: Path, *args: str, check: bool = True) -> subprocess.CompletedProcess[str]:
    return run(["git", *args], cwd=cwd, check=check)


def prepare_repo(
    repo: str,
    pr: str,
    info: dict[str, Any],
    root: Path,
    nixpkgs: Path | None,
) -> tuple[Path, Path, str, Path]:
    work_root = root / "worktrees"
    work_root.mkdir()
    base_tree = work_root / "base"
    head_tree = work_root / "head"

    if nixpkgs is None:
        repo_dir = root / "repo"
        repo_dir.mkdir()
        git(repo_dir, "init", "-q")
        git(repo_dir, "remote", "add", "origin", f"https://github.com/{repo}.git")
    else:
        repo_dir = nixpkgs.resolve()
        if not (repo_dir / ".git").exists():
            raise SystemExit(f"not a git checkout: {repo_dir}")

    merge_fetch = git(
        repo_dir,
        "fetch",
        "--filter=blob:none",
        "--depth=2",
        "origin",
        f"refs/pull/{pr}/merge",
        check=False,
    )
    if merge_fetch.returncode == 0:
        head_ref = git(repo_dir, "rev-parse", "FETCH_HEAD").stdout.strip()
        base_ref = git(repo_dir, "rev-parse", "FETCH_HEAD^1").stdout.strip()
        checkout_kind = "merge"
    else:
        if merge_fetch.stderr:
            print(merge_fetch.stderr.strip(), file=sys.stderr)
        git(
            repo_dir,
            "fetch",
            "--filter=blob:none",
            "--depth=1",
            "origin",
            f"refs/heads/{info['baseRefName']}",
            f"refs/pull/{pr}/head",
        )
        base_ref = info["baseRefOid"]
        head_ref = info["headRefOid"]
        checkout_kind = "head"

    git(repo_dir, "worktree", "add", "--detach", str(base_tree), base_ref)
    git(repo_dir, "worktree", "add", "--detach", str(head_tree), head_ref)
    return base_tree, head_tree, checkout_kind, repo_dir


def remove_worktree(repo: Path | None, path: Path | None) -> None:
    if repo is None or path is None or not path.exists():
        return
    git(repo, "worktree", "remove", "--force", str(path), check=False)


ATTR_RE = re.compile(r'^  ("(?:[^"\\]|\\.)+"|[A-Za-z0-9_+.-]+)\s*=')


def unquote_attr(name: str) -> str:
    if not name.startswith('"'):
        return name
    return json.loads(name)


def parse_top_level_attrs(path: Path) -> dict[str, str]:
    if not path.exists():
        return {}

    attrs: dict[str, list[str]] = {}
    current: str | None = None
    for line in path.read_text().splitlines(keepends=True):
        match = ATTR_RE.match(line)
        if match:
            current = unquote_attr(match.group(1))
            attrs[current] = [line]
        elif current is not None:
            attrs[current].append(line)

    return {name: "".join(lines) for name, lines in attrs.items()}


def changed_attrs(base: Path, head: Path, relative: Path) -> set[str]:
    base_attrs = parse_top_level_attrs(base / relative)
    head_attrs = parse_top_level_attrs(head / relative)
    names = set(base_attrs) | set(head_attrs)
    return {name for name in names if base_attrs.get(name) != head_attrs.get(name)}


def changed_files(base: Path, head: Path) -> list[str]:
    base_ref = git(base, "rev-parse", "HEAD").stdout.strip()
    head_ref = git(head, "rev-parse", "HEAD").stdout.strip()
    result = git(head, "diff", "--name-only", "--diff-filter=ACMRT", base_ref, head_ref)
    return [line for line in result.stdout.splitlines() if line]


def candidate_names(base: Path, head: Path) -> list[str]:
    files = changed_files(base, head)
    candidates: set[str] = set()

    if str(GENERATED) in files:
        candidates.update(changed_attrs(base, head, GENERATED))

    if str(OVERRIDES) in files:
        candidates.update(changed_attrs(base, head, OVERRIDES))

    for file_name in files:
        path = Path(file_name)
        try:
            relative = path.relative_to(PATCHES)
        except ValueError:
            continue
        if relative.parts:
            candidates.add(relative.parts[0])

    return sorted(candidates)


def write_json(path: Path, value: Any) -> None:
    path.write_text(json.dumps(value, indent=2, sort_keys=True))


def eval_actual_changed(
    base: Path,
    head: Path,
    candidates: list[str],
    systems: list[str],
    root: Path,
) -> tuple[list[str], list[dict[str, Any]]]:
    names_json = root / "candidate-names.json"
    systems_json = root / "systems.json"
    eval_nix = root / "actual-changed.nix"
    write_json(names_json, candidates)
    write_json(systems_json, systems)
    eval_nix.write_text(
        f"""
with builtins;
let
  names = fromJSON (readFile {json.dumps(str(names_json))});
  systems = fromJSON (readFile {json.dumps(str(systems_json))});
  basePath = {json.dumps(str(base))};
  headPath = {json.dumps(str(head))};

  mkPkgs =
    path: system:
    import path {{
      inherit system;
      config = {{
        allowAliases = false;
        allowBroken = false;
        allowUnfree = true;
      }};
    }};

  firstPkgs = mkPkgs headPath (head systems);
  inherit (firstPkgs) lib;

  mkPkgsBySystem =
    path:
    listToAttrs (
      map (system: {{
        name = system;
        value = mkPkgs path system;
      }}) systems
    );

  basePkgs = mkPkgsBySystem basePath;
  headPkgs = mkPkgsBySystem headPath;

  inspect =
    pkgs: name:
    let
      pkgEval = tryEval (lib.attrByPath [ "vimPlugins" name ] null pkgs);
      pkg = pkgEval.value;
      isDrvEval = tryEval (lib.isDerivation pkg);
      exists = pkgEval.success && isDrvEval.success && isDrvEval.value;
      pathEval = tryEval (if exists then unsafeDiscardStringContext "${{pkg}}" else null);
    in
    if exists && pathEval.success then
      {{ status = "ok"; path = pathEval.value; }}
    else if pkgEval.success && pkg == null then
      {{ status = "missing"; }}
    else
      {{ status = "error"; }};

  changes = lib.concatMap (
    name:
    lib.concatMap (
      system:
      let
        baseValue = inspect basePkgs.${{system}} name;
        headValue = inspect headPkgs.${{system}} name;
      in
      lib.optional (baseValue != headValue) {{
        inherit name system;
        base = baseValue;
        head = headValue;
      }}
    ) systems
  ) names;
in
{{
  changedNames = lib.unique (map (change: change.name) changes);
  inherit changes;
}}
""".lstrip()
    )
    result = run(
        [
            "nix",
            "eval",
            "--json",
            "--file",
            str(eval_nix),
            "--option",
            "lint-url-literals",
            "fatal",
            "--show-trace",
            "--no-allow-import-from-derivation",
        ]
    )
    data = json.loads(result.stdout)
    return data["changedNames"], data["changes"]


def nix_attr(name: str) -> str:
    if re.match(r"^[A-Za-z_][A-Za-z0-9_'-]*$", name):
        return f"vimPlugins.{name}"
    return f"vimPlugins.{json.dumps(name)}"


def review_changed(
    pr: str,
    names: list[str],
    systems: list[str],
    review_args: list[str],
) -> int:
    command = [
        "nixpkgs-review",
        "pr",
        pr,
        "--systems",
        " ".join(systems),
        *review_args,
    ]
    for name in names:
        command.extend(["-p", nix_attr(name)])

    print(f"running nixpkgs-review with {len(names)} vimPlugins attrs", file=sys.stderr)
    return run(command, check=False, capture=False).returncode


def split_systems(value: str | None) -> list[str]:
    if value:
        return value.split()
    result = run(
        ["nix", "eval", "--raw", "--impure", "--expr", "builtins.currentSystem"]
    )
    return [result.stdout.strip()]


def has_option(args: list[str], name: str) -> bool:
    return any(arg == name or arg.startswith(f"{name}=") for arg in args)


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Run nixpkgs-review for only vimPlugins attrs whose evaluated output changed in a nixpkgs PR.",
    )
    parser.add_argument("pr", help="nixpkgs PR number or GitHub PR URL")
    parser.add_argument(
        "--repo", default="NixOS/nixpkgs", help="GitHub repo, default: NixOS/nixpkgs"
    )
    parser.add_argument(
        "--systems", help="space-separated systems, default: current system"
    )
    parser.add_argument(
        "--num-eval-workers",
        type=int,
        help="nixpkgs-review eval workers, default: nixpkgs-review default",
    )
    parser.add_argument(
        "--nixpkgs", type=Path, help="existing nixpkgs checkout to fetch into"
    )
    parser.add_argument(
        "--list", action="store_true", help="print changed vimPlugins attrs and exit"
    )
    parser.add_argument(
        "--no-build",
        action="store_true",
        help="compute changed attrs without running nixpkgs-review",
    )
    parser.add_argument(
        "--details", action="store_true", help="print per-system path changes as JSON"
    )
    parser.add_argument(
        "--keep-worktree", action="store_true", help="keep temporary worktree"
    )
    args, review_args = parser.parse_known_args()
    if review_args[:1] == ["--"]:
        review_args = review_args[1:]
    if not has_option(review_args, "--eval"):
        review_args = ["--eval", "local", *review_args]
    if args.num_eval_workers is not None and not has_option(
        review_args, "--num-eval-workers"
    ):
        review_args = [
            "--num-eval-workers",
            str(args.num_eval_workers),
            *review_args,
        ]

    require_tool("git")
    require_tool("gh")
    require_tool("nix")
    if not args.list and not args.no_build:
        require_tool("nixpkgs-review")

    pr = parse_pr_number(args.pr)
    systems = split_systems(args.systems)

    temp_dir = Path(tempfile.mkdtemp(prefix=f"vim-plugins-review-{pr}-"))
    base: Path | None = None
    head: Path | None = None
    repo_dir: Path | None = None
    try:
        info = pr_info(args.repo, pr)
        print(f"PR {pr}: {info['title']}", file=sys.stderr)
        base, head, checkout_kind, repo_dir = prepare_repo(
            args.repo, pr, info, temp_dir, args.nixpkgs
        )
        print(f"checkout: {checkout_kind}", file=sys.stderr)

        candidates = candidate_names(base, head)
        if not candidates:
            print("no vimPlugins candidates found", file=sys.stderr)
            return 0

        print(f"candidates: {len(candidates)}", file=sys.stderr)
        changed, details = eval_actual_changed(
            base, head, candidates, systems, temp_dir
        )
        print(f"actual changed: {len(changed)}", file=sys.stderr)
        removed_names = {
            name
            for name in changed
            if all(
                entry["head"]["status"] == "missing"
                for entry in details
                if entry["name"] == name
            )
        }
        if removed_names:
            print(
                "skipping removed vimPlugins attrs: "
                + ", ".join(f"vimPlugins.{name}" for name in sorted(removed_names)),
                file=sys.stderr,
            )
        changed = [name for name in changed if name not in removed_names]

        if args.details:
            print(json.dumps(details, indent=2, sort_keys=True))
        else:
            for name in changed:
                print(f"vimPlugins.{name}")

        if args.list or args.no_build or not changed:
            return 0

        return review_changed(pr, changed, systems, review_args)
    finally:
        if args.keep_worktree:
            print(f"kept worktree: {temp_dir}", file=sys.stderr)
        else:
            remove_worktree(repo_dir, base)
            remove_worktree(repo_dir, head)
            shutil.rmtree(temp_dir)


if __name__ == "__main__":
    raise SystemExit(main())
