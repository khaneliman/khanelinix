#!/usr/bin/env python3

import re
import subprocess
import sys
from pathlib import Path

RAYCAST_REPO = "https://github.com/raycast/extensions.git"
REV_RE = re.compile(r'(^\s*raycastRev\s*=\s*")([0-9a-f]{40})(";\s*$)', re.MULTILINE)
ENTRY_RE = re.compile(
    r'(?P<prefix>\{\s*name = "(?P<name>[^"]+)";\s*sha256 = ")'
    r'(?P<hash>sha256-[^"]+)'
    r'(?P<suffix>";\s*\})',
    re.DOTALL,
)
GOT_HASH_RE = re.compile(r"got:\s*(sha256-[A-Za-z0-9+/=]+)")


def run(
    command: list[str], *, cwd: Path | None = None, check: bool = True
) -> subprocess.CompletedProcess[str]:
    result = subprocess.run(
        command,
        cwd=cwd,
        text=True,
        capture_output=True,
    )
    if check and result.returncode != 0:
        sys.stderr.write(result.stdout)
        sys.stderr.write(result.stderr)
        raise SystemExit(result.returncode)
    return result


def get_repo_root() -> Path:
    print("Resolving repository root...", flush=True)
    result = run(["git", "rev-parse", "--show-toplevel"])
    return Path(result.stdout.strip())


def get_head_rev() -> str:
    print("Resolving latest raycast/extensions HEAD revision...", flush=True)
    result = run(["git", "ls-remote", RAYCAST_REPO, "HEAD"])
    return result.stdout.split()[0]


def get_extension_names(text: str) -> list[str]:
    return [match.group("name") for match in ENTRY_RE.finditer(text)]


def get_sparse_hash(repo_root: Path, name: str, rev: str) -> str:
    expr = f"""
let
  flake = builtins.getFlake (toString {repo_root});
  pkgs = import flake.inputs.nixpkgs {{ system = builtins.currentSystem; }};
in
pkgs.fetchgit {{
  url = "https://github.com/raycast/extensions";
  rev = "{rev}";
  hash = pkgs.lib.fakeHash;
  sparseCheckout = [ "/extensions/{name}" ];
}}
"""
    result = run(["nix", "build", "--impure", "--no-link", "--expr", expr], check=False)
    output = f"{result.stdout}\n{result.stderr}"
    match = GOT_HASH_RE.search(output)
    if match is None:
        sys.stderr.write(output)
        raise SystemExit(f"failed to compute hash for {name}")
    return match.group(1)


def replace_rev(text: str, rev: str) -> str:
    updated, count = REV_RE.subn(rf"\g<1>{rev}\g<3>", text, count=1)
    if count != 1:
        raise SystemExit("failed to update raycastRev in Vicinae module")
    return updated


def replace_hashes(text: str, hashes: dict[str, str]) -> str:
    seen: set[str] = set()

    def repl(match: re.Match[str]) -> str:
        name = match.group("name")
        hash_value = hashes.get(name)
        if hash_value is None:
            return match.group(0)
        seen.add(name)
        return f"{match.group('prefix')}{hash_value}{match.group('suffix')}"

    updated = ENTRY_RE.sub(repl, text)
    missing = [name for name in hashes if name not in seen]
    if missing:
        raise SystemExit(
            "failed to update inline Vicinae hashes for: " + ", ".join(sorted(missing))
        )
    return updated


def main() -> None:
    repo_root = get_repo_root()
    module_path = (
        repo_root / "modules/home/programs/graphical/launchers/vicinae/default.nix"
    )
    print(f"Using module: {module_path}", flush=True)
    text = module_path.read_text()
    names = get_extension_names(text)
    print(f"Found {len(names)} pinned extensions in inline list", flush=True)
    rev = get_head_rev()

    print(f"Updating Vicinae Raycast extensions to {rev}")
    hashes: dict[str, str] = {}
    for index, name in enumerate(names, start=1):
        print(
            f"[{index}/{len(names)}] Computing sparse fetch hash for extensions/{name}",
            flush=True,
        )
        hash_value = get_sparse_hash(repo_root, name, rev)
        print(f"[{index}/{len(names)}] Resolved {name} -> {hash_value}", flush=True)
        hashes[name] = hash_value

    print("Rewriting inline Raycast pins...", flush=True)
    updated = replace_hashes(replace_rev(text, rev), hashes)
    module_path.write_text(updated)
    print(f"Updated {module_path}", flush=True)


if __name__ == "__main__":
    main()
