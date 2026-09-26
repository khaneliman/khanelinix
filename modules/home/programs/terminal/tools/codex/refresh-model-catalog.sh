catalog_path=$1
bundled_path=$2
catalog_url=$3
api_key=$4
codex_binary=$5
mode=${6-}

mkdir -p -- "$(dirname -- "$catalog_path")"
catalog_tmp=$(mktemp "$catalog_path.XXXXXX")
trap 'rm -f -- "$catalog_tmp"' EXIT

if [[ ! -s $bundled_path ]]; then
    "$codex_binary" debug models --bundled >"$catalog_tmp"
    mv -- "$catalog_tmp" "$bundled_path"
fi

if [[ $mode == --bundled-only ]]; then
    exit 0
fi

# A local catalog bypasses Codex's 1 MiB remote-catalog limit without
# dropping the model-specific prompts or capability metadata.
catalog_override=$(jq -rn --arg path "$catalog_tmp" '"model_catalog_json=" + ($path | tojson)')
if curl --fail --silent --show-error --connect-timeout 1 --max-time 5 \
    -H "Authorization: Bearer $api_key" "$catalog_url" >"$catalog_tmp" &&
    jq -e '.models | type == "array" and length > 0' "$catalog_tmp" >/dev/null &&
    "$codex_binary" -c "$catalog_override" debug models >/dev/null; then
    mv -- "$catalog_tmp" "$catalog_path"
elif [[ -s $catalog_path ]]; then
    echo "codex: gateway catalog refresh failed; using the cached catalog" >&2
else
    cp -- "$bundled_path" "$catalog_tmp"
    mv -- "$catalog_tmp" "$catalog_path"
    echo "codex: gateway catalog unavailable; using bundled model metadata" >&2
fi
