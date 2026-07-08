#!/usr/bin/env sh
# okf-memory: SessionStart hook for Codex.
# Named okf-memory-* to avoid colliding with planning-with-files' own
# session-start.sh in the same merged /etc/codex/hooks/ directory.
set -u

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
sh "${SCRIPT_DIR}/okf-memory-user-prompt-submit.sh"
exit 0
