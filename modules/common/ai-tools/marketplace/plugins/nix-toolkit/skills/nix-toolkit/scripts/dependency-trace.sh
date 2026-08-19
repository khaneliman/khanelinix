#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'USAGE'
usage: dependency-trace.sh <target-installable-or-store-path> [dependency-installable-or-store-path]

Resolves the target output, prints direct runtime references, and optionally
runs runtime and derivation `nix why-depends` checks for a dependency.
USAGE
}

if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
    usage >&2
    exit 2
fi

resolve_output() {
    local target="$1"

    case "$target" in
    /nix/store/*) printf '%s\n' "$target" ;;
    *) nix build --no-link --print-out-paths "$target" | head -n1 ;;
    esac
}

target_input="$1"
target_out="$(resolve_output "$target_input")"

printf 'target input: %s\ntarget output: %s\n\n' "$target_input" "$target_out"
printf '== direct runtime references ==\n'
nix-store -q --references "$target_out" | sort

printf '\n== recursive closure summary ==\n'
nix path-info -rSh "$target_out" | sort -h

if [ "$#" -eq 2 ]; then
    dep_input="$2"
    dep_out="$(resolve_output "$dep_input")"

    printf '\ndependency input: %s\ndependency output: %s\n' "$dep_input" "$dep_out"

    printf '\n== runtime why-depends ==\n'
    nix why-depends "$target_out" "$dep_out" || true

    printf '\n== derivation why-depends ==\n'
    nix why-depends --derivation "$target_input" "$dep_input" || true

    dep_name="$(basename "$dep_out" | sed -E 's/^[a-z0-9]{32}-//')"
    dep_pkg_name="$(printf '%s\n' "$dep_name" | sed -E 's/-(bin|debug|dev|doc|info|lib|man|out|static)$//')"

    printf '\n== closure entries matching dependency output name ==\n'
    nix path-info -r "$target_out" | grep -F -- "$dep_name" || true

    if [ "$dep_pkg_name" != "$dep_name" ]; then
        printf '\n== closure entries matching dependency package name ==\n'
        nix path-info -r "$target_out" | grep -F -- "$dep_pkg_name" || true
    fi
fi
