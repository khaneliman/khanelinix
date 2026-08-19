#!/usr/bin/env sh
# planning-with-files: emit a fixed-shape, cache-stable run-ledger summary (v3).
#
# This replaces raw `tail -20 progress.md` injection in autonomous mode. The
# output is synthesized from the machine ledger and task_plan.md status counts
# only: NO free text from disk reaches the model context, and there are NO
# timestamps, so the injected block is KV-cache stable by construction
# (architecture C3 injection rule).
#
# Plan-dir resolution (via resolve-plan-dir.sh):
#   1. $PLAN_ID env var -> ./.planning/$PLAN_ID/
#   2. ./.planning/.active_plan
#   3. Newest ./.planning/<dir>/ by mtime
#   4. Legacy: project root
#
# Usage:
#   sh scripts/ledger-summary.sh
#
# Output block (stable shape):
#   === RUN LEDGER ===
#   entries: <N>
#   phases: <complete>/<total> complete
#   in_progress: <phase heading or none>
#   agent <name>: <last event type>
#   ...
#   ==================

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RESOLVER="${SCRIPT_DIR}/resolve-plan-dir.sh"

resolve_plan_dir() {
    plan_dir=""
    if [ -f "${RESOLVER}" ]; then
        plan_dir="$(sh "${RESOLVER}" 2>/dev/null)"
    fi
    if [ -n "${plan_dir}" ] && [ -d "${plan_dir}" ]; then
        printf "%s\n" "${plan_dir}"
        return 0
    fi
    printf "%s\n" "."
    return 0
}

PLAN_DIR="$(resolve_plan_dir)"

if [ "${PLAN_DIR}" = "." ]; then
    PLAN_FILE="./task_plan.md"
else
    PLAN_FILE="${PLAN_DIR}/task_plan.md"
fi

# --- Phase counts: identical grep patterns to check-complete.sh ---
TOTAL=0
COMPLETE=0
IN_PROGRESS=0
IN_PROGRESS_HEADING="none"
if [ -f "${PLAN_FILE}" ]; then
    TOTAL=$(grep -c "### Phase" "${PLAN_FILE}" 2>/dev/null || true)
    COMPLETE=$(grep -cF "**Status:** complete" "${PLAN_FILE}" 2>/dev/null || true)
    IN_PROGRESS=$(grep -cF "**Status:** in_progress" "${PLAN_FILE}" 2>/dev/null || true)

    # Fallback to inline [status] format when **Status:** is absent.
    if [ "${COMPLETE}" -eq 0 ] && [ "${IN_PROGRESS}" -eq 0 ]; then
        c2=$(grep -c "\[complete\]" "${PLAN_FILE}" 2>/dev/null || true)
        i2=$(grep -c "\[in_progress\]" "${PLAN_FILE}" 2>/dev/null || true)
        : "${c2:=0}"
        : "${i2:=0}"
        if [ "${c2}" -gt 0 ] || [ "${i2}" -gt 0 ]; then
            COMPLETE="${c2}"
            IN_PROGRESS="${i2}"
        fi
    fi

    # Heading of the FIRST phase whose status block is in_progress. We walk
    # phase headings and look ahead for the status line so the summary names
    # the active phase without leaking any plan body text beyond the heading.
    heading=""
    state=""
    # shellcheck disable=SC2162
    while IFS= read -r line; do
        case "${line}" in
        "### Phase"*)
            heading="${line}"
            ;;
        *"**Status:** in_progress"*)
            if [ -n "${heading}" ]; then
                IN_PROGRESS_HEADING="${heading}"
                break
            fi
            ;;
        *"[in_progress]"*)
            if [ -n "${heading}" ] && [ "${IN_PROGRESS_HEADING}" = "none" ]; then
                IN_PROGRESS_HEADING="${heading}"
            fi
            ;;
        esac
    done <"${PLAN_FILE}"
fi
: "${TOTAL:=0}"
: "${COMPLETE:=0}"
: "${IN_PROGRESS:=0}"

# --- Ledger stats: total entries + last event type per agent ---
TOTAL_ENTRIES=0
for f in "${PLAN_DIR}"/ledger-*.jsonl; do
    [ -f "${f}" ] || continue
    n=$(grep -c '"tick"' "${f}" 2>/dev/null || true)
    : "${n:=0}"
    TOTAL_ENTRIES=$((TOTAL_ENTRIES + n))
done

printf '=== RUN LEDGER ===\n'
printf 'entries: %s\n' "${TOTAL_ENTRIES}"
printf 'phases: %s/%s complete\n' "${COMPLETE}" "${TOTAL}"
printf 'in_progress: %s\n' "${IN_PROGRESS_HEADING}"

# Per-agent last event type. Agent name comes from the filename
# (ledger-<agent>.jsonl); the last event is parsed from the final line.
for f in "${PLAN_DIR}"/ledger-*.jsonl; do
    [ -f "${f}" ] || continue
    base="$(basename "${f}")"
    agent="${base#ledger-}"
    agent="${agent%.jsonl}"
    last_line="$(tail -n 1 "${f}" 2>/dev/null)"
    last_event="$(printf '%s' "${last_line}" | sed -n 's/.*"event"[[:space:]]*:[[:space:]]*"\([A-Za-z_]*\)".*/\1/p')"
    [ -z "${last_event}" ] && last_event="none"
    printf 'agent %s: %s\n' "${agent}" "${last_event}"
done

printf '==================\n'
exit 0
