# Nix Toolkit Scripts

Use scripts for first-pass reports and repeatable measurements; use mode
playbooks when diagnosis or custom command shaping is needed.

## Available Scripts

- `<path-to-skill>/scripts/package_diff_report.py --before <installable>
  --after <installable>`:
  build without result links or lock-file updates, compare deterministic file
  manifests and closures, and emit bounded stable JSON. Add `--diffoscope` for
  bounded normalized structural excerpts.
- `scripts/closure-diff-report.sh <before> <after>`: build two installables
  without linking and report closure drift.
- `scripts/dependency-trace.sh <target> [dependency]`: inspect direct
  references, recursive closure, and optional `why-depends` paths.
- `scripts/package-option-scan.sh <package-list-installable> [pattern]`: inspect
  package-list options without building package or system closure.
- `scripts/drv-graph-grep.sh [--allow-meta] <derivation> <pattern>`: instantiate
  derivation graph and search drv names without realizing outputs.
- `scripts/eval-benchmark.sh [--runs N] [--warmup N] <eval command...>`:
  benchmark eval commands and capture `NIX_SHOW_STATS`.

Run script `--help` first when present.
