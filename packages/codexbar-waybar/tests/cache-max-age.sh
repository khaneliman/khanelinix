#!/usr/bin/env bash

set -euo pipefail

wrapper="$1"
stale_cache="$2"
wrapper_shell="$3"
failed_codexbar="$4"

test_root="$(mktemp -d)"
trap 'rm -rf "$test_root"' EXIT

cache_dir="$test_root/cache/codexbar-waybar"
mkdir -p "$cache_dir"

run_wrapper() {
    local max_age="$1"

    install -m0644 "$stale_cache" "$cache_dir/last.json"
    HOME="$test_root/home" \
        XDG_CACHE_HOME="$test_root/cache" \
        CODEXBAR_BIN="$failed_codexbar" \
        CODEXBAR_PROVIDERS=claude \
        CODEXBAR_STAGGER=0 \
        CODEXBAR_CACHE_MAX_AGE="$max_age" \
        "$wrapper_shell" "$wrapper"
}

expired_output="$(run_wrapper 3600)"
jq -e '
    .class == "stale"
    and .percentage == 0
    and .tooltip == "CodexBar: no provider data"
' <<<"$expired_output" >/dev/null
jq -e 'length == 0' "$cache_dir/last.json" >/dev/null

unbounded_output="$(run_wrapper 0)"
jq -e '
    .class == "stale"
    and .percentage == 15.68
    and (.tooltip | contains("Claude primary: 11.12%"))
    and (.tooltip | contains("Claude secondary: 15.68%"))
' <<<"$unbounded_output" >/dev/null
