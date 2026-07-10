#!/usr/bin/env sh
# Emit only a routing nudge. Planning state stays on disk and is read on demand.
set -u

[ "${PLANNING_DISABLED:-}" = "1" ] && exit 0

CONTEXT="userprompt"
for arg in "$@"; do
    case "$arg" in
    --context=*) CONTEXT="${arg#--context=}" ;;
    esac
done

SCRIPT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)"
PLAN_DIR="$(sh "${SCRIPT_DIR}/resolve-plan-dir.sh" 2>/dev/null)"
PLAN_FILE="${PLAN_DIR:+${PLAN_DIR}/}task_plan.md"

[ -f "$PLAN_FILE" ] || exit 0

if [ -n "$PLAN_DIR" ]; then
    ATTESTATION_FILE="${PLAN_DIR}/.attestation"
else
    ATTESTATION_FILE=".plan-attestation"
fi

if [ -f "$ATTESTATION_FILE" ]; then
    EXPECTED="$(tr -d '\r\n[:space:]' <"$ATTESTATION_FILE" 2>/dev/null)"
    ACTUAL="$(
        sha256sum "$PLAN_FILE" 2>/dev/null || shasum -a 256 "$PLAN_FILE" 2>/dev/null
    )"
    ACTUAL="${ACTUAL%% *}"
    if [ -n "$EXPECTED" ] && [ "$ACTUAL" != "$EXPECTED" ]; then
        echo '[planning-with-files] Plan changed after attestation. Re-attest approved content before continuing.'
        exit 0
    fi
fi

case "$CONTEXT" in
userprompt)
    printf '%s\n' "[planning-with-files] Active plan: ${PLAN_FILE}. Read before major decisions; update phase status and progress after meaningful work; store research in findings.md."
    ;;
precompact)
    printf '%s\n' "[planning-with-files] Compaction imminent. Flush current phase and progress to ${PLAN_FILE}; context recovers from disk."
    ;;
esac

exit 0
