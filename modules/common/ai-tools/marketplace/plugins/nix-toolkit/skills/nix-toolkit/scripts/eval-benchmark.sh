#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'USAGE'
usage: eval-benchmark.sh [--runs N] [--warmup N] <eval-command...>

Benchmarks an evaluation command with eval cache disabled. If hyperfine is not
on PATH, runs it through `nix shell nixpkgs#hyperfine`.

example:
  eval-benchmark.sh --runs 10 --warmup 3 \
    nix eval --raw .#nixosConfigurations.host.config.system.build.toplevel.drvPath
USAGE
}

runs=10
warmup=3

while [ "$#" -gt 0 ]; do
    case "$1" in
    --runs)
        runs="$2"
        shift 2
        ;;
    --warmup)
        warmup="$2"
        shift 2
        ;;
    -h | --help)
        usage
        exit 0
        ;;
    --)
        shift
        break
        ;;
    *)
        break
        ;;
    esac
done

if [ "$#" -eq 0 ]; then
    usage >&2
    exit 2
fi

if command -v hyperfine >/dev/null 2>&1; then
    hyperfine_cmd=(hyperfine)
else
    hyperfine_cmd=(nix shell nixpkgs#hyperfine -c hyperfine)
fi

printf 'benchmark command:'
printf ' %q' "$@"
printf ' --option eval-cache false\n'

"${hyperfine_cmd[@]}" --warmup "$warmup" --runs "$runs" -- \
    "$* --option eval-cache false"

stats_file="$(mktemp)"
trap 'rm -f "$stats_file"' EXIT

printf '\n== evaluator stats, single run ==\n'
NIX_SHOW_STATS=1 NIX_SHOW_STATS_PATH="$stats_file" "$@" --option eval-cache false >/dev/null
jq '
  {
    nrThunks,
    nrAvoided,
    nrValues,
    sets: .nrOpUpdateValuesCopied,
    gcTotalBytes: .gc.totalBytes
  }
  | with_entries(select(.value != null))
' "$stats_file"
