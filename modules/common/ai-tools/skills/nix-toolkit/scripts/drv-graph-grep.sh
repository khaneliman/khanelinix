#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'USAGE'
usage: drv-graph-grep.sh [--allow-meta] <derivation-installable-or-drv-path> <name-pattern>

Instantiates a derivation graph and searches derivation names. This does not
realize/build outputs. Use --allow-meta only for diagnosis when broken,
insecure, unsupported, or unfree package checks block graph creation.

example:
  drv-graph-grep.sh nixpkgs#hello glibc
USAGE
}

allow_meta=0

while [ "$#" -gt 0 ]; do
    case "$1" in
    --allow-meta)
        allow_meta=1
        shift
        ;;
    -h | --help)
        usage
        exit 0
        ;;
    *)
        break
        ;;
    esac
done

if [ "$#" -ne 2 ]; then
    usage >&2
    exit 2
fi

target="$1"
pattern="$2"

resolve_drv() {
    local installable="$1"

    case "$installable" in
    /nix/store/*.drv) printf '%s\n' "$installable" ;;
    *.drv) printf '%s\n' "$installable" ;;
    *)
        if [ "$allow_meta" -eq 1 ]; then
            env \
                NIXPKGS_ALLOW_BROKEN=1 \
                NIXPKGS_ALLOW_INSECURE=1 \
                NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM=1 \
                NIXPKGS_ALLOW_UNFREE=1 \
                nix eval --impure --raw --option eval-cache false "${installable}.drvPath"
        else
            nix eval --raw --option eval-cache false "${installable}.drvPath"
        fi
        ;;
    esac
}

drv="$(resolve_drv "$target")"
printf 'target: %s\ndrv: %s\n\n' "$target" "$drv"

nix derivation show -r "$drv" |
    jq -r --arg pattern "$pattern" '
      .derivations
      | keys[]
      | select(test($pattern; "i"))
      | "/nix/store/" + .
    '
