#!/usr/bin/env sh
# planning-with-files: Pre-tool-use hook for Codex

# issue #195: per-invocation opt-out for one-shot/CI sessions. Still emit the
# allow decision so the tool call proceeds; only the plan context is skipped.
if [ "${PLANNING_DISABLED:-}" = "1" ]; then
    echo '{"decision": "allow"}'
    exit 0
fi

HOOK_DIR="$(cd "$(dirname "$0")" 2>/dev/null && pwd)"
PLAN_DIR="$(sh "${HOOK_DIR}/resolve-plan-dir.sh" 2>/dev/null)"
PLAN_FILE="${PLAN_DIR:+${PLAN_DIR}/}task_plan.md"

if [ -f "$PLAN_FILE" ]; then
    # Log plan context to stderr so the Codex adapter can surface it as systemMessage.
    head -30 "$PLAN_FILE" >&2
fi

echo '{"decision": "allow"}'
exit 0
