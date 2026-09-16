#!/usr/bin/env bash
# Report which files define a module option, at which priority, without an
# interactive REPL. Read-only; realizes nothing.
set -euo pipefail

usage() {
    cat <<'EOF'
Usage: option-forensics.sh [options] <config-installable> <option.path>

  <config-installable>  Flake attribute of an evaluated configuration, such as
                        .#nixosConfigurations.host
                        .#darwinConfigurations.host
                        '.#homeConfigurations."user@host"'
                        Any lib.evalModules result works.
  <option.path>         Dot-separated option path, e.g. services.openssh.enable

Options:
  --values        Also render each definition value as JSON. Forces the value,
                  which can instantiate derivations and produce large output.
  --limit N       Cap listed files and definitions (default 40, 0 disables).
  --raw           Emit the underlying JSON instead of the text report.
  -h, --help      Show this help.

Exit codes: 0 report produced, 2 usage error, 3 evaluation failed.

Option-path segments are quoted individually, so hyphens and other odd
characters are safe. A segment containing a literal dot cannot be addressed;
use `nix repl` for that case.
EOF
}

want_values=false
limit=40
raw=false
args=()

while [ $# -gt 0 ]; do
    case "$1" in
    --values)
        want_values=true
        shift
        ;;
    --limit)
        [ $# -ge 2 ] || {
            echo "error: --limit needs a value" >&2
            exit 2
        }
        limit="$2"
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
    --)
        shift
        while [ $# -gt 0 ]; do
            args+=("$1")
            shift
        done
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

if [ "${#args[@]}" -ne 2 ]; then
    usage >&2
    exit 2
fi

config_attr="${args[0]}"
option_path="${args[1]}"

case "$limit" in
'' | *[!0-9]*)
    echo "error: --limit must be a non-negative integer" >&2
    exit 2
    ;;
esac

# Build a quoted attribute chain so segments with hyphens resolve correctly.
selector=""
IFS='.' read -r -a segments <<<"$option_path"
for segment in "${segments[@]}"; do
    [ -n "$segment" ] || {
        echo "error: empty segment in option path: $option_path" >&2
        exit 2
    }
    selector="${selector}.\"${segment}\""
done

if [ "$want_values" = true ]; then
    definitions_expr='map (d: {
        inherit (d) file;
        value =
          let rendered = builtins.tryEval (builtins.toJSON d.value);
          in if rendered.success then rendered.value else "<unrenderable>";
      }) opt.definitionsWithLocations'
else
    definitions_expr='[ ]'
fi

apply_expr="cfg:
  let
    opt = cfg.options${selector};
  in {
    isDefined = opt.isDefined or false;
    highestPrio = opt.highestPrio or null;
    type = opt.type.description or \"unknown\";
    files = opt.files or [ ];
    definitions = ${definitions_expr};
  }"

# Keep stderr out of the captured JSON; nix warnings would corrupt it.
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

printf '%s' "$json" | jq -r --arg option "$option_path" --argjson limit "$limit" '
  def strip_store: sub("^/nix/store/[a-z0-9]{32}-[^/]*/"; "");
  def priority_label:
    if . == null then "none"
    elif . >= 9999 then "\(.) (no definitions at all)"
    elif . >= 1500 then "\(.) (mkOptionDefault, i.e. the option default)"
    elif . >= 1000 then "\(.) (mkDefault)"
    elif . >= 100 then "\(.) (plain assignment)"
    elif . >= 60 then "\(.) (mkImageMediaOverride)"
    elif . >= 50 then "\(.) (mkForce)"
    else "\(.) (mkVMOverride or stronger)"
    end;
  def cap(xs): if $limit == 0 then xs else xs[0:$limit] end;

  (.files | map(strip_store) | unique) as $files
  | (.definitions | map(.file |= strip_store)) as $defs
  | "option:      \($option)",
    "type:        \(.type)",
    "defined:     \(.isDefined)",
    "priority:    \(.highestPrio | priority_label)",
    "files:       \($files | length) distinct",
    (cap($files)[] | "  \(.)"),
    (if $limit > 0 and ($files | length) > $limit
     then "  ... \(($files | length) - $limit) more (raise --limit)" else empty end),
    (if ($defs | length) > 0 then "definitions:" else empty end),
    (cap($defs)[] | "  \(.file)\n    \(.value)"),
    (if $limit > 0 and ($defs | length) > $limit
     then "  ... \(($defs | length) - $limit) more (raise --limit)" else empty end)
'
