#!/usr/bin/env bash
set -euo pipefail

skill_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

fail() {
    echo "validate-snippets: $*" >&2
    exit 1
}

# Attribute paths that intentionally do not resolve against nixpkgs lib or the
# running evaluator. Each entry needs a reason; an unexplained entry is a bug
# being suppressed.
#   builtins.parallel - Determinate Nix only, behind the parallel-eval
#                       experimental feature, absent from upstream Nix.
allowed_missing=(
    "builtins.parallel"
)

extract_blocks() {
    local file="$1" fence="$2" ext="$3"
    awk -v out="$tmp_dir/$(basename "$file")." -v fence="\`\`\`$fence" -v ext="$ext" '
    $0 == fence { in_block = 1; n++; next }
    /^```$/ && in_block { in_block = 0; next }
    in_block { print > out n ext }
  ' "$file"
}

for file in "$skill_dir"/references/*.md; do
    extract_blocks "$file" bash .sh
done

for snippet in "$tmp_dir"/*.sh; do
    [ -e "$snippet" ] || continue
    bash -n "$snippet"
done

for script in "$skill_dir"/scripts/*.sh; do
    bash -n "$script"
done

# Boolean Nix settings generate --flag and --no-flag, neither taking an
# argument. `--allow-import-from-derivation false` leaves `false` to be parsed
# as an installable. Require the --option form for any flag given a value.
for snippet in "$tmp_dir"/*.sh; do
    [ -e "$snippet" ] || continue
    if grep -nE -- '--[a-z][a-z0-9-]+[[:space:]]+(true|false)\b' "$snippet" |
        grep -qv -- '--option'; then
        grep -nE -- '--[a-z][a-z0-9-]+[[:space:]]+(true|false)\b' "$snippet" >&2
        fail "boolean flag given a value without --option in $(basename "$snippet")"
    fi
done

# Resolve every lib.* and builtins.* attribute path named in the references
# against real nixpkgs. A parse check cannot catch a function that does not
# exist; shipping lib.types.isRawType is what motivated this.
# Scan only code contexts: nix fences and inline code spans. Prose carries
# markdown link targets such as builtins.html that are not attribute paths.
for file in "$skill_dir"/references/*.md; do
    extract_blocks "$file" nix .nix
    grep -oE '`[^`]+`' "$file" || true
done >"$tmp_dir/code-context.txt"
cat "$tmp_dir"/*.nix >>"$tmp_dir/code-context.txt" 2>/dev/null || true

grep -hoE "\b(lib|builtins)\.[A-Za-z_][A-Za-z0-9_'.]*" "$tmp_dir/code-context.txt" |
    sed "s/[.]*$//" |
    sort -u >"$tmp_dir/attrpaths.txt"

for allowed in "${allowed_missing[@]}"; do
    grep -vxF "$allowed" "$tmp_dir/attrpaths.txt" >"$tmp_dir/attrpaths.filtered" || true
    mv "$tmp_dir/attrpaths.filtered" "$tmp_dir/attrpaths.txt"
done

jq -R -s 'split("\n") | map(select(length > 0))' <"$tmp_dir/attrpaths.txt" \
    >"$tmp_dir/attrpaths.json"

missing="$(
    nix eval --impure --raw --expr "
      let
        pkgs = import <nixpkgs> { };
        inherit (pkgs) lib;
        paths = builtins.fromJSON (builtins.readFile $tmp_dir/attrpaths.json);
        resolve =
          path:
          let
            parts = lib.splitString \".\" path;
            root = builtins.head parts;
            rest = builtins.tail parts;
          in
          if root == \"lib\" then
            lib.hasAttrByPath rest lib
          else
            builtins.all (p: builtins.hasAttr p builtins) rest;
      in
      lib.concatStringsSep \"\n\" (builtins.filter (p: !resolve p) paths)
    "
)"

if [ -n "$missing" ]; then
    echo "$missing" >&2
    fail "attribute paths above do not resolve in nixpkgs lib or builtins"
fi

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
