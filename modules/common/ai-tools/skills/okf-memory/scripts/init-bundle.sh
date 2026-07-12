#!/usr/bin/env sh
# okf-memory: scaffold or repair a project/user bundle without overwriting
# existing memory. Idempotent and safe to re-run.
set -u

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
SCOPE="${1:-project}"
case "$SCOPE" in
project)
    BUNDLE_DIR="$(sh "${SCRIPT_DIR}/resolve-bundle-dir.sh")"
    ;;
--user)
    BUNDLE_DIR="$(sh "${SCRIPT_DIR}/resolve-bundle-dir.sh" --user)"
    ;;
*)
    echo "usage: $0 [--user]" >&2
    exit 2
    ;;
esac

mkdir -p "${BUNDLE_DIR}/concepts"

if [ ! -f "${BUNDLE_DIR}/index.md" ]; then
    cat >"${BUNDLE_DIR}/index.md" <<'EOF'
---
type: index
---

# Index

Entry point for this project's OKF knowledge bundle. Links to concept docs
live here as they're added under `concepts/`.

See also: [MEMORY.local.md](MEMORY.local.md), [log.md](log.md).
EOF
fi

if [ ! -f "${BUNDLE_DIR}/log.md" ]; then
    cat >"${BUNDLE_DIR}/log.md" <<EOF
---
type: log
---

# Log

Chronological record of updates to this bundle. Append new entries at the
bottom.

- $(date +%Y-%m-%d): bundle created.
EOF
fi

if [ ! -f "${BUNDLE_DIR}/MEMORY.local.md" ]; then
    cat >"${BUNDLE_DIR}/MEMORY.local.md" <<'EOF'
---
type: memory
---

No curated memory yet — see concepts/ for full detail.
EOF
fi

if [ "$SCOPE" = "project" ]; then
    ROOT="$(dirname "$BUNDLE_DIR")"
    GITIGNORE="${ROOT}/.gitignore"
    if [ -f "$GITIGNORE" ]; then
        grep -qxF '.okf/MEMORY.local.md' "$GITIGNORE" 2>/dev/null ||
            printf '\n# okf-memory: local, uncommitted curated memory\n.okf/MEMORY.local.md\n' >>"$GITIGNORE"
    else
        printf '# okf-memory: local, uncommitted curated memory\n.okf/MEMORY.local.md\n' >"$GITIGNORE"
    fi
fi

echo "[okf-memory] bundle ready at ${BUNDLE_DIR}"
