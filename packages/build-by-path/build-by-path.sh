#! /usr/bin/env nix-shell
#! nix-shell -i bash
# shellcheck shell=bash
# Build nixpkgs packages by path without completely evaluating nixpkgs
#
# Usage:
#   build-by-path.sh [--fast] NIXPKGS_PATH ATTR_PATH [SYSTEM] [-- NIX_FAST_BUILD_ARGS...]
#
# Examples:
#   build-by-path.sh --fast . 'vimPlugins' 'aarch64-darwin'
#   build-by-path.sh . 'vimPlugins'
#   build-by-path.sh ~/nixpkgs hello 'x86_64-linux'

set -euo pipefail

FAST_BUILD=0
if [ "${1:-}" = "--fast" ]; then
    FAST_BUILD=1
    shift
fi

FAST_BUILD_ARGS=()
POSITIONAL_ARGS=()
while [ "$#" -gt 0 ]; do
    if [ "$1" = "--" ]; then
        shift
        FAST_BUILD_ARGS=("$@")
        break
    fi

    POSITIONAL_ARGS+=("$1")
    shift
done
set -- "${POSITIONAL_ARGS[@]}"

if [ "$#" -lt 2 ] || [ "$#" -gt 3 ]; then
    echo "Usage: $0 [--fast] NIXPKGS_PATH ATTR_PATH [SYSTEM] [-- NIX_FAST_BUILD_ARGS...]"
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

cat >"$TMP_DIR/to-list.nix" <<EOF
let
  root-path = "$ATTR_PATH";
  nixpkgs-path = "$NIXPKGS_PATH";
  system = "$SYSTEM";

  pkgs = import nixpkgs-path {
    inherit system;
    config = {
      allowAliases = false;
      allowBroken = false;
    };
  };
  inherit (pkgs) lib;

  root = lib.attrByPath (lib.splitString "." root-path) null pkgs;
  evaluatedRoot = builtins.tryEval root;
in
if !evaluatedRoot.success || evaluatedRoot.value == null then
  throw "Attribute path '\${root-path}' was not found"
else if lib.isDerivation evaluatedRoot.value then
  [ "" ]
else
  builtins.attrNames evaluatedRoot.value
EOF

nix eval \
    --json \
    --file "$TMP_DIR/to-list.nix" \
    --option lint-url-literals fatal \
    --show-trace \
    --no-allow-import-from-derivation \
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
      allowAliases = false;
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
      evaluatedPkg = tryEval (lib.attrByPath attrPath null pkgs);
      pkg = evaluatedPkg.value;
      evaluatedIsDerivation = tryEval (lib.isDerivation pkg);
      exists =
        evaluatedPkg.success
        && pkg != null
        && evaluatedIsDerivation.success
        && evaluatedIsDerivation.value
        && lib.hasAttrByPath attrPath pkgs;
    in
    if !exists then
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
if $FAST_BUILD == 1 then
  listToAttrs (
    map (package: {
      inherit (package) name;
      value = package.path;
    }) filteredPackages
  )
else
  pkgs.linkFarm "test" filteredPackages
EOF

if [ "$FAST_BUILD" = 1 ]; then
    nix-fast-build \
        --file "$TMP_DIR/to-build.nix" \
        --option lint-url-literals fatal \
        --no-link \
        --systems "$SYSTEM" \
        "${FAST_BUILD_ARGS[@]}"
else
    "$NIX" build \
        --file "$TMP_DIR/to-build.nix" \
        --extra-experimental-features 'nix-command' \
        --option lint-url-literals fatal \
        --no-link \
        --keep-going \
        --show-trace \
        --no-allow-import-from-derivation \
        --nix-path "$NIXPKGS_PATH"
fi
