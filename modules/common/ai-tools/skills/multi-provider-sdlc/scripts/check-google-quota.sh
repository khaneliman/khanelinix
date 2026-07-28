#!/usr/bin/env bash
set -euo pipefail

if ! command -v codexbar >/dev/null 2>&1 || ! command -v jq >/dev/null 2>&1; then
    printf '%s\n' '{"provider":"google","status":"unknown","reason":"quota-tool-unavailable"}'
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

printf '%s\n' "$usage_json" | jq -c \
    '
    def summarize($windows; $models):
      [$windows[] | select(.window.usedPercent | type == "number")] as $known
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
          ($blocked | max_by(.window.usedPercent)) as $window
          | {
              status: "exhausted",
              usedPercent: $window.window.usedPercent,
              resetsAt: ($window.window.resetsAt // null),
              models: $models
            }
        else
          ($known | max_by(.window.usedPercent)) as $window
          | {
              status: "available",
              usedPercent: $window.window.usedPercent,
              resetsAt: ($window.window.resetsAt // null),
              models: $models
            }
        end;

    .[0].usage.extraRateWindows as $windows
    | {
        provider: "google",
        pools: {
          "claude-gpt": summarize(
            [$windows[] | select(.id | startswith("antigravity-quota-summary-3p-"))];
            ["google-opus-4-6", "google-sonnet-4-6", "gpt-oss-120b"]
          ),
          gemini: summarize(
            [$windows[] | select(.id | startswith("antigravity-quota-summary-gemini-"))];
            ["gemini-3-1-pro", "gemini-3-6-flash"]
          )
        }
      }
  '
