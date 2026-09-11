#!/usr/bin/env sh
# planning-with-files: User prompt submit hook for Codex

# issue #195: per-invocation opt-out for one-shot/CI sessions (e.g. codex exec)
# that share a cwd with a plan but never opted into it.
[ "${PLANNING_DISABLED:-}" = "1" ] && exit 0

HOOK_DIR="$(cd "$(dirname "$0")" 2>/dev/null && pwd)"
PLAN_DIR="$(sh "${HOOK_DIR}/resolve-plan-dir.sh" 2>/dev/null)"
[ -n "${PLAN_DIR}" ] || exit 0
PLAN_FILE="${PLAN_DIR:+${PLAN_DIR}/}task_plan.md"

# Keep the legacy root-plan display and attestation filename when the root was
# explicitly attached. Named plans retain their resolved path.
if [ "${PLAN_DIR}" = "${PWD}" ]; then
    PLAN_DIR=""
    PLAN_FILE="task_plan.md"
fi

if [ -f "$PLAN_FILE" ]; then
    if [ -n "$PLAN_DIR" ]; then
        ATTESTATION_FILE="${PLAN_DIR}/.attestation"
    else
        ATTESTATION_FILE=".plan-attestation"
    fi
    if [ -f "$ATTESTATION_FILE" ]; then
        EXPECTED="$(tr -d '\r\n[:space:]' <"$ATTESTATION_FILE" 2>/dev/null)"
        ACTUAL="$(sha256sum "$PLAN_FILE" 2>/dev/null || shasum -a 256 "$PLAN_FILE" 2>/dev/null)"
        ACTUAL="${ACTUAL%% *}"
        if [ -n "$EXPECTED" ] && [ "$ACTUAL" != "$EXPECTED" ]; then
            echo '[planning-with-files] Plan changed after attestation. Re-attest approved content before continuing.'
            exit 0
        fi
    fi
    echo "[planning-with-files] Active plan: ${PLAN_FILE}. Read before major decisions; update phase status and progress after meaningful work; store research in findings.md."
fi
exit 0
