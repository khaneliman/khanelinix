#!/usr/bin/env sh
# planning-with-files: User prompt submit hook for Codex

# issue #195: per-invocation opt-out for one-shot/CI sessions (e.g. codex exec)
# that share a cwd with a plan but never opted into it.
[ "${PLANNING_DISABLED:-}" = "1" ] && exit 0

HOOK_DIR="$(cd "$(dirname "$0")" 2>/dev/null && pwd)"
PLAN_DIR="$(sh "${HOOK_DIR}/resolve-plan-dir.sh" 2>/dev/null)"
PLAN_FILE="${PLAN_DIR:+${PLAN_DIR}/}task_plan.md"

# Session isolation: if .planning/sessions/ exists, only attached sessions see
# plan context. Absence of the sessions dir means legacy single-session mode —
# all sessions in the cwd receive context to preserve backward compatibility.
if [ -d ".planning/sessions" ]; then
    SESSION_ID="${PWF_SESSION_ID:-}"
    if [ -z "$SESSION_ID" ] || [ ! -f ".planning/sessions/${SESSION_ID}.attached" ]; then
        exit 0
    fi
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
