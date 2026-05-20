#!/usr/bin/env bash
set -euo pipefail

skill_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

extract_bash_blocks() {
    local file="$1"
    awk -v out="$tmp_dir/$(basename "$file")." '
    /^```bash$/ { in_block = 1; n++; next }
    /^```$/ && in_block { in_block = 0; next }
    in_block { print > out n ".sh" }
  ' "$file"
}

for file in "$skill_dir"/references/*.md; do
    extract_bash_blocks "$file"
done

for snippet in "$tmp_dir"/*.sh; do
    [ -e "$snippet" ] || continue
    bash -n "$snippet"
done

for script in "$skill_dir"/scripts/*.sh; do
    bash -n "$script"
done

# shellcheck disable=SC2016
nix-instantiate --parse -E '
  { remote, package }:
  let
    parts = builtins.split ":" remote;
    owner = builtins.elemAt parts 0;
    branch = builtins.elemAt parts 2;
    pkgs = import (fetchTarball {
      url = "https://github.com/${owner}/nixpkgs/archive/${branch}.tar.gz";
    }) {};
  in pkgs.${package}
' >/dev/null

nix-build --help | grep -q -- "--argstr"
nix build --help | grep -q -- "--dry-run"
nix build --help | grep -q -- "--no-link"
nix build --help | grep -q -- "--rebuild"
nix path-info --help | grep -q -- "--json"
nix why-depends --help | grep -q -- "--derivation"
nix store diff-closures --help >/dev/null
nix derivation show --help >/dev/null
nix flake metadata --help | grep -q -- "--inputs-from"
nix flake update --help | grep -q -- "nix flake update"

echo "nix-toolkit snippets validated"
