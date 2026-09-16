#!/usr/bin/env bash
# Report failed assertions and warnings for a configuration without building it.
set -euo pipefail

usage() {
    cat <<'EOF'
Usage: config-assertions.sh [options] <config-installable>

  <config-installable>  Flake attribute of an evaluated configuration, such as
                        .#nixosConfigurations.host
                        .#darwinConfigurations.host
                        '.#homeConfigurations."user@host"'

Options:
  --all        Also list assertions that pass.
  --raw        Emit JSON instead of the text report.
  -h, --help   Show this help.

Exit codes: 0 no failed assertions, 1 at least one assertion failed,
2 usage error, 3 evaluation failed.

Warnings never affect the exit code. A failed assertion here is the same one
that would stop a build, found without realizing any derivation.
EOF
}

show_all=false
raw=false
config_attr=""

while [ $# -gt 0 ]; do
    case "$1" in
    --all)
        show_all=true
        shift
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
        if [ -n "$config_attr" ]; then
            echo "error: unexpected argument: $1" >&2
            exit 2
        fi
        config_attr="$1"
        shift
        ;;
    esac
done

[ -n "$config_attr" ] || {
    usage >&2
    exit 2
}

apply_expr='cfg: {
  failed = map (a: a.message) (builtins.filter (a: !a.assertion) cfg.config.assertions);
  passed = builtins.length (builtins.filter (a: a.assertion) cfg.config.assertions);
  warnings = cfg.config.warnings;
}'

stderr_file="$(mktemp)"
trap 'rm -f "$stderr_file"' EXIT

if ! json="$(nix eval --json "$config_attr" --apply "$apply_expr" 2>"$stderr_file")"; then
    cat "$stderr_file" >&2
    echo "error: evaluation failed; the configuration may not evaluate at all" >&2
    exit 3
fi

cat "$stderr_file" >&2

if [ "$raw" = true ]; then
    printf '%s\n' "$json"
else
    printf '%s' "$json" | jq -r --argjson showAll "$show_all" '
      "failed assertions: \(.failed | length)",
      (.failed[] | "  ✗ \(.)"),
      (if $showAll then "passing assertions: \(.passed)" else empty end),
      "warnings: \(.warnings | length)",
      (.warnings[] | "  ! \(. | rtrimstr("\n") | gsub("\n"; "\n    "))")
    '
fi

failed_count="$(printf '%s' "$json" | jq '.failed | length')"
[ "$failed_count" -eq 0 ] || exit 1
