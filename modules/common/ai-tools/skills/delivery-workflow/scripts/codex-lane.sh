#!/usr/bin/env bash
set -euo pipefail

usage() {
    printf '%s\n' \
        'usage: codex-lane <mode> [--plan PATH] [--base REF] [--write] -- <task>' \
        'modes: spark discover probe test implement plan-review code-review debug' >&2
    exit 2
}

[[ $# -gt 0 ]] || usage
mode=$1
shift

plan_path=
base_ref=
allow_write=false
while [[ $# -gt 0 ]]; do
    case "$1" in
    --plan)
        [[ $# -ge 2 ]] || usage
        plan_path=$2
        shift 2
        ;;
    --base)
        [[ $# -ge 2 ]] || usage
        base_ref=$2
        shift 2
        ;;
    --write)
        allow_write=true
        shift
        ;;
    --)
        shift
        break
        ;;
    *) usage ;;
    esac
done

[[ $# -gt 0 ]] || usage
task=$*
timeout_seconds=${CODEX_LANE_TIMEOUT_SECONDS:-600}
[[ $timeout_seconds =~ ^[1-9][0-9]*$ ]] || {
    printf 'codex-lane: CODEX_LANE_TIMEOUT_SECONDS must be a positive integer\n' >&2
    exit 2
}

command -v codex >/dev/null || {
    printf 'codex-lane: codex executable not found\n' >&2
    exit 127
}
command -v git >/dev/null || {
    printf 'codex-lane: git executable not found\n' >&2
    exit 127
}
command -v timeout >/dev/null || {
    printf 'codex-lane: GNU timeout executable not found\n' >&2
    exit 127
}

repo_root=$(git rev-parse --show-toplevel 2>/dev/null) || {
    printf 'codex-lane: run inside a Git repository\n' >&2
    exit 2
}
repo_root=$(cd "$repo_root" && pwd -P)

resolve_repo_file() {
    local requested=$1
    local directory
    local resolved
    [[ -f $requested ]] || {
        printf 'codex-lane: file not found: %s\n' "$requested" >&2
        return 1
    }
    directory=$(cd "$(dirname "$requested")" && pwd -P)
    resolved="$directory/$(basename "$requested")"
    case "$resolved" in
    "$repo_root"/*) printf '%s\n' "${resolved#"$repo_root"/}" ;;
    *)
        printf 'codex-lane: file must be inside repository: %s\n' "$requested" >&2
        return 1
        ;;
    esac
}

plan_relative=
if [[ -n $plan_path ]]; then
    plan_relative=$(resolve_repo_file "$plan_path")
fi

if [[ -n $base_ref ]]; then
    git -C "$repo_root" rev-parse --verify --quiet "${base_ref}^{commit}" >/dev/null || {
        printf 'codex-lane: invalid base ref: %s\n' "$base_ref" >&2
        exit 2
    }
fi

skill_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)
profile=
sandbox=
schema="$skill_root/schemas/worker.json"
lane_instruction=

case "$mode" in
spark)
    profile=spark
    sandbox=read-only
    lane_instruction='Handle obvious low-risk task. Stay concise. Do not edit files.'
    if [[ $allow_write == true ]]; then
        sandbox=workspace-write
        lane_instruction='Make only explicitly requested mechanical edit in one file. Refuse architecture, security, schema, migration, concurrency, or broad behavior changes. Preserve unrelated work and run focused validation.'
    fi
    ;;
discover)
    profile=quick
    sandbox=read-only
    lane_instruction='Gather bounded read-only repository evidence. Do not edit or run state-changing commands.'
    ;;
probe)
    profile=quick
    sandbox=workspace-write
    lane_instruction='Run bounded non-destructive reproduction or measurement. Build artifacts are allowed; do not modify tracked source.'
    ;;
test)
    profile=quick
    sandbox=workspace-write
    lane_instruction='Run requested validation and summarize signal. Build artifacts are allowed; do not modify tracked source or fix failures.'
    ;;
implement)
    profile=quick
    sandbox=workspace-write
    lane_instruction='Implement only supplied approved scope. Preserve unrelated changes. Run focused validation. Do not commit, push, merge, publish, or open a pull request.'
    ;;
plan-review)
    profile=deep
    sandbox=read-only
    schema="$skill_root/schemas/review.json"
    lane_instruction='Review supplied plan for correctness, missing dependencies, validation gaps, scope risk, and reversible sequencing. Stay inside supplied scope, use at most 12 repository commands, and do not edit or run validation.'
    ;;
code-review)
    profile=deep
    sandbox=read-only
    schema="$skill_root/schemas/review.json"
    lane_instruction='Review current repository diff for correctness, regressions, missing tests, security, and instruction compliance. Stay inside supplied scope, use at most 12 repository commands, rank only actionable findings, and do not edit or run validation.'
    ;;
debug)
    profile=deep
    sandbox=read-only
    lane_instruction='Diagnose supplied ambiguous failure from evidence. Test bounded hypotheses read-only. Propose minimal fix but do not edit.'
    ;;
*) usage ;;
esac

if [[ $allow_write == true && $mode != spark ]]; then
    printf 'codex-lane: --write is only valid for spark\n' >&2
    exit 2
fi
if [[ $mode == plan-review && -z $plan_relative ]]; then
    printf 'codex-lane: plan-review requires --plan PATH\n' >&2
    exit 2
fi
if [[ -n $plan_relative && $mode != plan-review && $mode != implement ]]; then
    printf 'codex-lane: --plan is only valid for plan-review or implement\n' >&2
    exit 2
fi
if [[ -n $base_ref && $mode != code-review ]]; then
    printf 'codex-lane: --base is only valid for code-review\n' >&2
    exit 2
fi

tmp_dir=$(mktemp -d)
trap 'rm -r -- "$tmp_dir"' EXIT
prompt_file="$tmp_dir/prompt.md"
result_file="$tmp_dir/result.json"
stderr_file="$tmp_dir/stderr.log"

{
    printf 'You are a fresh bounded worker in delivery-workflow.\n'
    printf 'Follow repository instruction chain. Parent retains architecture and final decisions.\n'
    printf 'Lane: %s\nInstruction: %s\n' "$mode" "$lane_instruction"
    [[ -z $plan_relative ]] || printf 'Approved/reviewed plan path: %s\n' "$plan_relative"
    [[ -z $base_ref ]] || printf 'Review base ref: %s\n' "$base_ref"
    printf '\nTask:\n%s\n' "$task"
    printf '\nReturn only JSON matching supplied output schema. Keep evidence bounded.\n'
} >"$prompt_file"

codex_args=(
    exec
    --strict-config
    --profile "$profile"
    --ephemeral
    --cd "$repo_root"
    --sandbox "$sandbox"
    --config 'approval_policy="never"'
    --config 'web_search="disabled"'
    --output-schema "$schema"
    --output-last-message "$result_file"
    --color never
    -
)

worker_status=0
timeout --signal=TERM --kill-after=5s "${timeout_seconds}s" \
    codex "${codex_args[@]}" <"$prompt_file" >/dev/null 2>"$stderr_file" || worker_status=$?

if [[ $worker_status -eq 124 || $worker_status -eq 137 ]]; then
    printf 'codex-lane: worker timed out after %s seconds\n' "$timeout_seconds" >&2
    exit 124
fi
if [[ $worker_status -ne 0 ]]; then
    printf 'codex-lane: worker failed\n' >&2
    tail -n 20 "$stderr_file" >&2
    exit 1
fi

[[ -s $result_file ]] || {
    printf 'codex-lane: worker returned no structured result\n' >&2
    exit 1
}
printf '%s\n' "$(<"$result_file")"
