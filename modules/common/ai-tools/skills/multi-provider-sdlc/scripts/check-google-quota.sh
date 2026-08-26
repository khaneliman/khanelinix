#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
registry="$script_dir/../references/model-routing.json"

if ! command -v codexbar >/dev/null 2>&1 || ! command -v jq >/dev/null 2>&1; then
    printf '%s\n' '{"provider":"google","status":"unknown","reason":"quota-tool-unavailable"}'
    exit 0
fi

if [[ ! -r $registry ]] || ! jq -e '.schema_version == 2 and (.models | type == "object")' "$registry" >/dev/null 2>&1; then
    printf '%s\n' '{"provider":"google","status":"unknown","reason":"routing-registry-unavailable"}'
    exit 0
fi

usage_json=""
for attempt in 1 2 3; do
    usage_json="$(codexbar usage --provider antigravity --source cli --json 2>/dev/null || true)"
    if printf '%s\n' "$usage_json" | jq -e '
    (.[0].usage.extraRateWindows // []) | length > 0
  ' >/dev/null 2>&1; then
        break
    fi
    if [[ $attempt -lt 3 ]]; then
        sleep 2
    fi
done

if ! printf '%s\n' "$usage_json" | jq -e '
  (.[0].usage.extraRateWindows // []) | length > 0
' >/dev/null 2>&1; then
    printf '%s\n' '{"provider":"google","status":"unknown","reason":"quota-data-missing"}'
    exit 0
fi

printf '%s\n' "$usage_json" | jq -c --slurpfile registry "$registry" \
    '
    def models_for($pool):
      [
        $registry[0].models
        | to_entries[]
        | select(.value.subscription == "google" and .value.quota_pool == $pool)
        | .key
      ] | sort;

    def summarize($windows; $pool):
      models_for($pool) as $models
      | [$windows[] | select(.window.usedPercent | type == "number")] as $known
      | [
          $known[]
          | select(
              .window.usedPercent >= 99.9
              or ((.window.resetDescription // "") | test("hit your .*limit"; "i"))
            )
        ] as $blocked
      | if ($known | length) == 0 then
          { status: "unknown", reason: "quota-data-missing", models: $models }
        elif ($blocked | length) > 0 then
          { status: "exhausted", models: $models }
        else
          { status: "available", models: $models }
        end;

    .[0].usage.extraRateWindows as $windows
    | {
        provider: "google",
        pools: {
          "claude-gpt": summarize(
            [$windows[] | select(.id | startswith("antigravity-quota-summary-3p-"))];
            "claude-gpt"
          ),
          gemini: summarize(
            [$windows[] | select(.id | startswith("antigravity-quota-summary-gemini-"))];
            "gemini"
          )
        }
      }
  '
