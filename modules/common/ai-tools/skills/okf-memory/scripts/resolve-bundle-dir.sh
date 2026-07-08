#!/usr/bin/env sh
# okf-memory: print the path to this project's .okf/ bundle directory.
# Does not create it — see init-bundle.sh for that. Always exits 0.
set -u

ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"
[ -n "$ROOT" ] || ROOT="$PWD"

printf '%s/.okf\n' "$ROOT"
