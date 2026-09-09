#!/usr/bin/env bash
set -euo pipefail

wrapper="$1"
wrapper_shell="$2"
test_root="$(mktemp -d)"
trap 'rm -rf "$test_root"' EXIT
mkdir -p "$test_root/codex" "$test_root/config/codexbar-waybar"
printf 'cli_auth_credentials_store = "auto"\n' >"$test_root/codex/config.toml"
printf '{"resetTimeFormat":"utc"}\n' >"$test_root/config/codexbar-waybar/state.json"
printf '#!%s\n' "$wrapper_shell" >"$test_root/secret-tool"
cat >>"$test_root/secret-tool" <<'SH'
sleep 0.6
printf '%s\n' '{"tokens":{"id_token":"header.eyJlbWFpbCI6InVzZXJAZXhhbXBsZS50ZXN0In0.signature","access_token":"fake-token","account_id":"workspace"}}'
SH
printf '#!%s\n' "$wrapper_shell" >"$test_root/codexbar"
cat >>"$test_root/codexbar" <<'SH'
cat "$FAKE_QUOTAS"
SH
chmod +x "$test_root/secret-tool" "$test_root/codexbar"

run_wrapper() {
    env -u CODEXBAR_RESET_TIME_FORMAT \
        HOME="$test_root/home" \
        XDG_CACHE_HOME="$test_root/cache" \
        XDG_CONFIG_HOME="$test_root/config" \
        CODEX_HOME="$test_root/codex" \
        CODEXBAR_BIN="$test_root/codexbar" \
        CODEXBAR_SECRET_TOOL="$test_root/secret-tool" \
        CODEXBAR_RESET_INVENTORY=1 \
        CODEXBAR_PROVIDERS=codex \
        CODEXBAR_PROVIDER_TIMEOUT=0.5 \
        FAKE_QUOTAS="$test_root/quotas.json" \
        "$wrapper_shell" "$wrapper"
}

# The keyring takes longer than the CLI timeout. Its optional work must not
# discard the completed quota. No email means no inventory network request.
printf '%s\n' '[{"provider":"codex","usage":{"secondary":{"usedPercent":40}}}]' >"$test_root/quotas.json"
output="$(run_wrapper)"
jq -e '.percentage == 40 and (.tooltip | contains("60% left"))' <<<"$output" >/dev/null

printf '%s\n' '[{"provider":"codex","usage":{"secondary":{"usedPercent":40},"codexResetCredits":{"availableCount":1,"credits":[{"status":"available","expires_at":"2099-10-05T04:18:34Z"}]}}}]' >"$test_root/quotas.json"
output="$(run_wrapper)"
jq -e '(.tooltip | contains("1 reset available")) and (.tooltip | contains("4:18 AM UTC"))' <<<"$output" >/dev/null
