#!/usr/bin/env bash
# Attach one session to one immutable plan choice.
# Usage: attach-session.sh <session_id> <plan_id|.>

set -euo pipefail

if [ "$#" -ne 2 ]; then
    echo "Usage: attach-session.sh <session_id> <plan_id|.>" >&2
    exit 2
fi

session_id="$1"
plan_id="$2"
if [[ ! "$session_id" =~ ^[A-Za-z0-9_][A-Za-z0-9._-]*$ ]]; then
    echo "Error: invalid session ID" >&2
    exit 1
fi
if [[ "$plan_id" != "." && ! "$plan_id" =~ ^[A-Za-z0-9_][A-Za-z0-9._-]*$ ]]; then
    echo "Error: invalid plan ID" >&2
    exit 1
fi

if [[ "$plan_id" == "." ]]; then
    plan_dir="$PWD"
else
    plan_dir="$PWD/.planning/$plan_id"
fi
if [ ! -f "$plan_dir/task_plan.md" ]; then
    echo "Error: task_plan.md not found for plan: $plan_id" >&2
    exit 1
fi

mkdir -p "$PWD/.planning/sessions"
sentinel="$PWD/.planning/sessions/$session_id.attached"
temporary="$(mktemp "$PWD/.planning/sessions/.${session_id}.attached.XXXXXX")"
trap 'rm -f "$temporary"' EXIT
printf '%s\n' "$plan_id" >"$temporary"
mv -f "$temporary" "$sentinel"
trap - EXIT
echo "Attached session $session_id to ${plan_id}."
