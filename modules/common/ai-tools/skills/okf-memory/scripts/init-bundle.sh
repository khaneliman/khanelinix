#!/usr/bin/env sh
# okf-memory: scaffold .okf/ in the current project if it doesn't already
# exist. Idempotent — safe to re-run. Always exits 0.
set -u

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
BUNDLE_DIR="$(sh "${SCRIPT_DIR}/resolve-bundle-dir.sh")"
ROOT="$(dirname "$BUNDLE_DIR")"

if [ -d "$BUNDLE_DIR" ]; then
    echo "[okf-memory] .okf/ already exists at ${BUNDLE_DIR}"
    exit 0
fi

mkdir -p "${BUNDLE_DIR}/concepts"

cat >"${BUNDLE_DIR}/index.md" <<'EOF'
---
type: index
---

# Index

Entry point for this project's OKF knowledge bundle. Links to concept docs
live here as they're added under `concepts/`.

See also: [MEMORY.local.md](MEMORY.local.md), [log.md](log.md).
EOF

cat >"${BUNDLE_DIR}/log.md" <<EOF
---
type: log
---

# Log

Chronological record of updates to this bundle. Append new entries at the
bottom.

- $(date +%Y-%m-%d): bundle created.
EOF

cat >"${BUNDLE_DIR}/MEMORY.local.md" <<'EOF'
---
type: memory
---

No curated memory yet — see concepts/ for full detail.
EOF

GITIGNORE="${ROOT}/.gitignore"
if [ -f "$GITIGNORE" ]; then
    grep -qxF '.okf/MEMORY.local.md' "$GITIGNORE" 2>/dev/null ||
        printf '\n# okf-memory: local, uncommitted curated memory\n.okf/MEMORY.local.md\n' >>"$GITIGNORE"
else
    printf '# okf-memory: local, uncommitted curated memory\n.okf/MEMORY.local.md\n' >"$GITIGNORE"
fi

echo "[okf-memory] scaffolded .okf/ at ${BUNDLE_DIR}"
