#!/usr/bin/env bash
# List an option subtree with its types, definition state, and priority tier.
set -euo pipefail

usage() {
    cat <<'EOF'
Usage: option-tree.sh [options] <config-installable> [option.path]

  <config-installable>  Flake attribute of an evaluated configuration.
  [option.path]         Subtree to list. Omit to list the whole tree, which is
                        large; prefer naming a prefix.

Options:
  --set-only     Only options something has actually defined.
  --unset-only   Only options still on their declared default.
  --depth N      Only options at most N levels below the given prefix.
  --limit N      Cap listed options (default 60, 0 disables).
  --raw          Emit JSON instead of the text report.
  -h, --help     Show this help.

Exit codes: 0 report produced, 2 usage error, 3 evaluation failed.

Use option-forensics.sh when you need the defining files for one option. This
script answers the wider question of what exists and what is set.
EOF
}

set_only=false
unset_only=false
depth=0
limit=60
raw=false
args=()

while [ $# -gt 0 ]; do
    case "$1" in
    --set-only)
        set_only=true
        shift
        ;;
    --unset-only)
        unset_only=true
        shift
        ;;
    --depth | --limit)
        [ $# -ge 2 ] || {
            echo "error: $1 needs a value" >&2
            exit 2
        }
        case "$2" in
        '' | *[!0-9]*)
            echo "error: $1 must be a non-negative integer" >&2
            exit 2
            ;;
        esac
        if [ "$1" = "--depth" ]; then depth="$2"; else limit="$2"; fi
        shift 2
        ;;
    --raw)
        raw=true
        shift
        ;;
    -h | --help)
        usage
        exit 0
        ;;
    -*)
        echo "error: unknown option: $1" >&2
        exit 2
        ;;
    *)
        args+=("$1")
        shift
        ;;
    esac
done

if [ "${#args[@]}" -lt 1 ] || [ "${#args[@]}" -gt 2 ]; then
    usage >&2
    exit 2
fi

if [ "$set_only" = true ] && [ "$unset_only" = true ]; then
    echo "error: --set-only and --unset-only are mutually exclusive" >&2
    exit 2
fi

config_attr="${args[0]}"
option_path="${args[1]:-}"

selector=""
if [ -n "$option_path" ]; then
    IFS='.' read -r -a segments <<<"$option_path"
    for segment in "${segments[@]}"; do
        [ -n "$segment" ] || {
            echo "error: empty segment in option path: $option_path" >&2
            exit 2
        }
        selector="${selector}.\"${segment}\""
    done
fi

# Walk with builtins only; the configuration's own lib is not always exposed.
apply_expr="cfg:
  let
    isOption = value: (value._type or \"\") == \"option\";
    walk = prefix: set:
      builtins.concatLists (builtins.attrValues (builtins.mapAttrs (name: value:
        if name == \"_module\" || !(builtins.isAttrs value) then [ ]
        else if isOption value then [ {
          path = prefix + name;
          type = value.type.description or \"unknown\";
          defined = value.isDefined or false;
          prio = value.highestPrio or null;
        } ]
        else walk (prefix + name + \".\") value) set));
  in walk \"\" cfg.options${selector}"

stderr_file="$(mktemp)"
trap 'rm -f "$stderr_file"' EXIT

if ! json="$(nix eval --json "$config_attr" --apply "$apply_expr" 2>"$stderr_file")"; then
    cat "$stderr_file" >&2
    echo "error: evaluation failed; the option path may not exist" >&2
    exit 3
fi

cat "$stderr_file" >&2

if [ "$raw" = true ]; then
    printf '%s\n' "$json"
    exit 0
fi

printf '%s' "$json" | jq -r \
    --arg prefix "$option_path" \
    --argjson setOnly "$set_only" \
    --argjson unsetOnly "$unset_only" \
    --argjson depth "$depth" \
    --argjson limit "$limit" '
  def tier:
    if . == null then "unset"
    elif . >= 9999 then "unset"
    elif . >= 1500 then "default"
    elif . >= 1000 then "mkDefault"
    elif . >= 100 then "set"
    elif . >= 60 then "mediaOverride"
    elif . >= 50 then "mkForce"
    else "vmOverride"
    end;

  def wanted:
    (if $setOnly then map(select(.prio != null and .prio < 1500)) else . end)
    | (if $unsetOnly then map(select(.prio == null or .prio >= 1500)) else . end)
    | (if $depth > 0 then map(select((.path | split(".") | length) <= $depth)) else . end);

  (. | wanted | sort_by(.path)) as $rows
  | ($rows | length) as $total
  | (if $prefix == "" then "prefix: (whole tree)" else "prefix: \($prefix)" end),
    "options: \($total)",
    "",
    ((if $limit == 0 then $rows else $rows[0:$limit] end)[]
      | "\(.prio | tier | . + "          "[0:(13 - length)]) \(.path)  [\(.type)]"),
    (if $limit > 0 and $total > $limit
     then "... \($total - $limit) more (raise --limit)" else empty end)
'
