#!/usr/bin/env sh
# Delegate Codex Stop gating to the skill's shared completion oracle.
set -u

[ "${PLANNING_DISABLED:-}" = "1" ] && exit 0

CONFIG_HOME="${XDG_CONFIG_HOME:-${HOME:-}/.config}"
SKILL_DIR="${PWF_SKILL_DIR:-${CONFIG_HOME}/codex/skills/planning-with-files}"
TARGET="${SKILL_DIR}/scripts/check-complete.sh"
BASH_BIN="$(command -v bash 2>/dev/null)"

[ -n "$BASH_BIN" ] && [ -f "$TARGET" ] || exit 0
exec "$BASH_BIN" "$TARGET" --gate
