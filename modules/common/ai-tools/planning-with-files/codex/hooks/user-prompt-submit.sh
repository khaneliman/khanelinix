#!/usr/bin/env sh
# planning-with-files: User prompt submit hook for Codex

# issue #195: per-invocation opt-out for one-shot/CI sessions (e.g. codex exec)
# that share a cwd with a plan but never opted into it.
[ "${PLANNING_DISABLED:-}" = "1" ] && exit 0

HOOK_DIR="$(cd "$(dirname "$0")" 2>/dev/null && pwd)"
PLAN_DIR="$(sh "${HOOK_DIR}/resolve-plan-dir.sh" 2>/dev/null)"
PLAN_FILE="${PLAN_DIR:+${PLAN_DIR}/}task_plan.md"
PROGRESS_FILE="${PLAN_DIR:+${PLAN_DIR}/}progress.md"

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
    echo "[planning-with-files] ACTIVE PLAN — current state:"
    head -50 "$PLAN_FILE"
    echo ""
    echo "=== recent progress ==="
    tail -20 "$PROGRESS_FILE" 2>/dev/null
    echo ""
    echo "[planning-with-files] Read findings.md for research context. Continue from the current phase."
fi
exit 0
