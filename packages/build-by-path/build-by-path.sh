#! /usr/bin/env nix-shell
#! nix-shell -i bash -p jq
# shellcheck shell=bash
# Build nixpkgs packages by path without completely evaluating nixpkgs
#
# Usage:
#   build-by-path.sh NIXPKGS_PATH ATTR_PATH [SYSTEM]
#
# Examples:
#   build-by-path.sh . 'vimPlugins' 'aarch64-darwin'
#   build-by-path.sh . 'vimPlugins'
#   build-by-path.sh ~/nixpkgs hello 'x86_64-linux'

set -euo pipefail

if [ "$#" -lt 2 ] || [ "$#" -gt 3 ]; then
    echo "Usage: $0 NIXPKGS_PATH ATTR_PATH [SYSTEM]"
    exit 1
fi

NIXPKGS_PATH=$(realpath "$1")
ATTR_PATH=$2
SYSTEM=${3:-$(nix eval --raw --impure --expr "builtins.currentSystem")}

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

if command -v nom >/dev/null 2>&1; then
    echo "NOM found, using it"
    NIX="nom"
else
    NIX="nix"
fi

echo "(import \"$NIXPKGS_PATH\" { }).$ATTR_PATH" >"$TMP_DIR/to-eval.nix"

nix-env \
    --option lint-url-literals fatal \
    --option system "$SYSTEM" \
    -f "$TMP_DIR/to-eval.nix" \
    -qaP \
    --json \
    --out-path \
    --show-trace \
    --no-allow-import-from-derivation |
    jq 'keys' \
        >"$TMP_DIR/attrs.json"

# https://github.com/Mic92/nixpkgs-review/blob/907925df227584ae4c0eb38db51fd23fe495d276/nixpkgs_review/nix/evalAttrs.nix
cat >"$TMP_DIR/to-build.nix" <<EOF
with builtins;
let
  root-path = "$ATTR_PATH";
  nixpkgs-path = "$NIXPKGS_PATH";
  system = "$SYSTEM";
  attr-json = "$TMP_DIR/attrs.json";

  pkgs = import nixpkgs-path {
    inherit system;
    config = {
      allowBroken = false;
    };
  };
  inherit (pkgs) lib;

  attrs = fromJSON (readFile attr-json);
  getProperties =
    name':
    let
      name = if name' == "" then root-path else name';
      stringAttrPath = if length attrs > 1 then root-path + "." + name else name;
      attrPath = lib.splitString "." stringAttrPath;
      pkg = lib.attrByPath attrPath null pkgs;
      exists = lib.hasAttrByPath attrPath pkgs;
    in
    if pkg == null || !exists then
      [ ]
    else
      lib.concatMap (
        output:
        let
          maybePath = tryEval "\${lib.getOutput output pkg}";
        in
        if maybePath.success then
          [
            {
              name = (if output == "out" then name else "\${name}.\${output}");
              path = pkg;
            }
          ]
        else
          [ ]
      ) (pkg.outputs or [ "out" ]);

  filteredPackages = concatMap getProperties attrs;
in
pkgs.linkFarm "test" filteredPackages
EOF

"$NIX" build \
    --file "$TMP_DIR/to-build.nix" \
    --extra-experimental-features 'nix-command' \
    --option lint-url-literals fatal \
    --no-link \
    --keep-going \
    --show-trace \
    --no-allow-import-from-derivation \
    --nix-path "$NIXPKGS_PATH"
