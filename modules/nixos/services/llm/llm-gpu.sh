# shellcheck shell=bash

usage() {
    cat <<'EOF'
Usage: llm-gpu status
       llm-gpu {llama-swap|ollama|desktop} [--apply]

Without --apply, show residency and the proposed unloads without changing it.
Wait for active requests to finish before using --apply.
EOF
}

mode=${1:-}
case "$mode:$#:${2:-}" in
status:1: | llama-swap:1: | ollama:1: | desktop:1: | \
    llama-swap:2:--apply | ollama:2:--apply | desktop:2:--apply) ;;
--help:1: | -h:1:)
    usage
    exit 0
    ;;
*)
    usage >&2
    exit 2
    ;;
esac

: "${swap_url:?set by the llm-gpu wrapper}" "${ollama_url:?set by the llm-gpu wrapper}"

request() {
    local timeout=$1
    shift
    curl -q --noproxy '*' --proto '=http' --fail --silent --show-error \
        --connect-timeout 5 --max-time "$timeout" "$@"
}

# Validate both inventories before changing either server.
swap_models=$(request 10 "$swap_url/running" | jq -ces '
  if length == 1 and (.[0].running | type == "array" and all(.[]; .model | type == "string" and length > 0))
  then .[0].running | map(.model)
  else error("unexpected llama-swap /running response")
  end
')
ollama_models=$(request 10 "$ollama_url/api/ps" | jq -ces '
  if length == 1 and (.[0].models | type == "array" and all(.[]; .name | type == "string" and length > 0))
  then .[0].models | map(.name)
  else error("unexpected Ollama /api/ps response")
  end
')

jq -n --argjson swap "$swap_models" --argjson ollama "$ollama_models" \
    '{"llama-swap": $swap, ollama: $ollama}'

if [[ $mode == status ]]; then
    exit 0
fi

if [[ $mode != llama-swap && $swap_models != '[]' ]]; then
    printf 'Unload llama-swap models: %s\n' "$swap_models"
    if [[ ${2:-} == --apply ]]; then
        request 60 --request POST "$swap_url/api/models/unload" >/dev/null
    fi
fi
if [[ $mode != ollama && $ollama_models != '[]' ]]; then
    printf 'Unload Ollama models: %s\n' "$ollama_models"
    if [[ ${2:-} == --apply ]]; then
        payloads=$(jq -c '.[] | {model: ., keep_alive: 0}' <<<"$ollama_models")
        while IFS= read -r payload; do
            request 60 --json "$payload" "$ollama_url/api/generate" >/dev/null
        done <<<"$payloads"
    fi
fi

if [[ ${2:-} == --apply ]]; then
    printf 'Check llm-gpu status and amdgpu_top before starting the next workload.\n'
fi
