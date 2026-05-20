#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'USAGE'
usage: closure-diff-report.sh <before-installable-or-store-path> <after-installable-or-store-path>

Builds installables without linking, compares closure size, runs
`nix store diff-closures`, and prints raw added/removed store paths.
USAGE
}

if [ "$#" -ne 2 ]; then
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

before_input="$1"
after_input="$2"
before_out="$(resolve_output "$before_input")"
after_out="$(resolve_output "$after_input")"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

printf 'before input: %s\nbefore output: %s\n' "$before_input" "$before_out"
nix path-info -Sh "$before_out"
printf '\nafter input: %s\nafter output: %s\n' "$after_input" "$after_out"
nix path-info -Sh "$after_out"

printf '\n== diff-closures ==\n'
nix store diff-closures "$before_out" "$after_out" || true

nix path-info -r "$before_out" | sort >"$tmp_dir/before.paths"
nix path-info -r "$after_out" | sort >"$tmp_dir/after.paths"

printf '\n== added paths ==\n'
comm -13 "$tmp_dir/before.paths" "$tmp_dir/after.paths" || true

printf '\n== removed paths ==\n'
comm -23 "$tmp_dir/before.paths" "$tmp_dir/after.paths" || true

printf '\n== largest after closure entries ==\n'
nix path-info --recursive --size --closure-size --human-readable "$after_out" |
    sort -h -k3,3 |
    tail -20
