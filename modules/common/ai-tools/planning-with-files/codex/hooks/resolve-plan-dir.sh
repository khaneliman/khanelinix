#!/usr/bin/env sh
# planning-with-files: resolve active plan directory.
#
# Resolve only the plan explicitly attached to $PWF_SESSION_ID.
# The repository active pointer and newest-plan fallback are intentionally not
# consulted by Codex hooks: they are mutable shared state.
#
# Always exits 0. Never errors out the agent loop.
#
# Usage:
#   PLAN_DIR="$(sh scripts/resolve-plan-dir.sh)"
#   PLAN_FILE="${PLAN_DIR:+$PLAN_DIR/}task_plan.md"

set -u

PLAN_ROOT="${1:-${PWD}/.planning}"
SESSIONS_DIR="${PLAN_ROOT}/sessions"

slug_is_valid() {
    case "$1" in
    '' | . | .[!.]*) return 1 ;;
    esac
    printf "%s" "$1" | grep -Eq '^[A-Za-z0-9_][A-Za-z0-9._-]*$'
}

if [ -z "${PWF_SESSION_ID:-}" ] || ! slug_is_valid "${PWF_SESSION_ID}"; then
    exit 0
fi

ATTACHMENT="${SESSIONS_DIR}/${PWF_SESSION_ID}.attached"
[ -f "${ATTACHMENT}" ] || exit 0
PLAN_ID="$(tr -d '\r\n' <"${ATTACHMENT}")"

if [ "${PLAN_ID}" = "." ]; then
    [ -f "${PWD}/task_plan.md" ] || exit 0
    printf "%s\n" "${PWD}"
    exit 0
fi

slug_is_valid "${PLAN_ID}" || exit 0
candidate="${PLAN_ROOT}/${PLAN_ID}"
[ -d "${candidate}" ] && [ -f "${candidate}/task_plan.md" ] || exit 0

root_real="$(realpath "${PWD}" 2>/dev/null || pwd)"
candidate_real="$(realpath "${candidate}" 2>/dev/null || true)"
case "${candidate_real}" in
"${root_real}"/*) printf "%s\n" "${candidate}" ;;
esac
exit 0
