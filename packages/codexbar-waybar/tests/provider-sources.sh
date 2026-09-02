#!/usr/bin/env bash

set -euo pipefail

wrapper="$1"
fake_codexbar_source="$2"
wrapper_shell="$3"

test_root="$(mktemp -d)"
trap 'rm -rf "$test_root"' EXIT

fake_codexbar="$test_root/fake-codexbar"
install -m0755 "$fake_codexbar_source" "$fake_codexbar"
sed -i "1c #!$wrapper_shell" "$fake_codexbar"

run_wrapper() {
    local antigravity_mode="$1"

    HOME="$test_root/home" \
        XDG_CACHE_HOME="$test_root/cache" \
        CODEXBAR_BIN="$fake_codexbar" \
        CODEXBAR_PROVIDERS="codex antigravity" \
        CODEXBAR_STAGGER=0 \
        CODEXBAR_PROVIDER_TIMEOUT=0 \
        FAKE_ANTIGRAVITY_MODE="$antigravity_mode" \
        "$wrapper_shell" "$wrapper"
}

output="$(run_wrapper offline)"

jq -e '
    .class == "ok"
    and .percentage == 40
    and (.tooltip | contains("Codex"))
    and (.tooltip | contains("Antigravity"))
    and (.tooltip | contains("quota unavailable"))
' <<<"$output" >/dev/null

jq -e '
    length == 1
    and .[0].provider == "codex"
    and .[0].source == "codex-cli"
' "$test_root/cache/codexbar-waybar/last.json" >/dev/null

zero_output="$(run_wrapper zero)"
jq -e '
    .class == "ok"
    and .percentage == 40
    and (.tooltip | contains("Antigravity"))
    and (.tooltip | contains("primary: 0%"))
' <<<"$zero_output" >/dev/null

jq -e '
    length == 2
    and any(.[];
        .provider == "antigravity"
        and .source == "cli"
        and .usage.primary.usedPercent == 0
        and .usage.secondary.usedPercent == 0)
' "$test_root/cache/codexbar-waybar/last.json" >/dev/null
