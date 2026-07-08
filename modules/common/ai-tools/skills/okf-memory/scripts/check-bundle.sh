#!/usr/bin/env sh
# okf-memory: OKF conformance + memory char-budget check.
#
# Usage: check-bundle.sh [bundle-dir]
# Defaults to ./.okf, which is correct when run from a repo root (pre-commit
# hooks run with cwd = repo root).
set -u

MEMORY_CHAR_BUDGET=2000

BUNDLE_DIR="${1:-.okf}"
STATUS=0

[ -d "$BUNDLE_DIR" ] || exit 0

has_nonempty_type() {
    file="$1"
    # Frontmatter is the block between the first two '---' lines.
    awk '/^---$/{n++; next} n==1' "$file" |
        grep -Eq '^type:[[:space:]]*[^[:space:]]'
}

if [ -d "${BUNDLE_DIR}/concepts" ]; then
    for f in "${BUNDLE_DIR}"/concepts/*.md; do
        [ -e "$f" ] || continue
        if ! has_nonempty_type "$f"; then
            echo "[okf-memory] ERROR: ${f} is missing a non-empty 'type:' frontmatter field" >&2
            STATUS=1
        fi
    done
fi

MEMORY_FILE="${BUNDLE_DIR}/MEMORY.local.md"
if [ -f "$MEMORY_FILE" ]; then
    BODY_CHARS=$(awk '/^---$/{n++; next} n>=2' "$MEMORY_FILE" | wc -m | tr -d '[:space:]')
    if [ "${BODY_CHARS:-0}" -gt "$MEMORY_CHAR_BUDGET" ]; then
        echo "[okf-memory] ERROR: ${MEMORY_FILE} body is ${BODY_CHARS} chars, over the ${MEMORY_CHAR_BUDGET}-char budget" >&2
        STATUS=1
    fi
fi

exit "$STATUS"
