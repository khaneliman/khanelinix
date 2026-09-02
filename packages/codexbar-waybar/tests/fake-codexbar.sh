#!/usr/bin/env bash

set -euo pipefail

provider=""
source_name=""
while (($# > 0)); do
    case "$1" in
    --provider)
        provider="$2"
        shift 2
        ;;
    --source)
        source_name="$2"
        shift 2
        ;;
    *)
        shift
        ;;
    esac
done

case "$provider:$source_name" in
codex:cli)
    printf '%s\n' '[{"provider":"codex","source":"codex-cli","usage":{"primary":{"usedPercent":12},"secondary":{"usedPercent":40}}}]'
    ;;
antigravity:cli)
    if [[ ${FAKE_ANTIGRAVITY_MODE:-offline} == "zero" ]]; then
        printf '%s\n' '[{"provider":"antigravity","source":"cli","usage":{"primary":{"usedPercent":0},"secondary":{"usedPercent":0}}}]'
    else
        printf '%s\n' '[{"provider":"antigravity","source":"offline","usage":{"loginMethod":"offline","primary":null,"secondary":null,"extraRateWindows":[{"id":"antigravity-offline-conversations","title":"Conversations","usageKnown":false,"window":{"usedPercent":0}}]}}]'
    fi
    ;;
*)
    printf '%s\n' "[{\"provider\":\"$provider\",\"error\":{\"message\":\"unexpected source: $source_name\"}}]"
    ;;
esac
