#!/usr/bin/env sh
# okf-memory: print the project or user OKF bundle directory.
# Does not create it — see init-bundle.sh for that.
set -u

if [ "${1:-}" = "--user" ]; then
    if [ -n "${OKF_USER_DIR:-}" ]; then
        printf '%s\n' "$OKF_USER_DIR"
    elif [ -n "${XDG_DATA_HOME:-}" ]; then
        printf '%s/okf\n' "$XDG_DATA_HOME"
    else
        printf '%s/.local/share/okf\n' "$HOME"
    fi
    exit 0
fi

if [ -n "${1:-}" ]; then
    echo "usage: $0 [--user]" >&2
    exit 2
fi

ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"
[ -n "$ROOT" ] || ROOT="$PWD"

printf '%s/.okf\n' "$ROOT"
