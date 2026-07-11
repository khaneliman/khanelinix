---
name: sarif-toolkit
description: Deterministic SARIF reporting and partitioning. Use when inspecting .sarif or .sarif.json static-analysis output, summarizing findings without loading full JSON into chat, or splitting results by rule, path, severity, or balanced chunks.
---

# SARIF Toolkit

Use bundled script for mechanical inspection. Keep interpretation and fix
prioritization with agent.

## Report

```bash
python3 <skill-dir>/scripts/sarif_report.py <file> --format markdown
```

Report includes schema/version, runs, tools, result and artifact counts, top
rules, severity counts, affected paths, and bounded representative results.
Scalar values, tools, severities, and split-file listings are bounded by default
with total/omitted metadata. Use `--help` to adjust limits; `0` means unlimited
for `--max-*` flags.

## Split

Write chunks only when user asks:

```bash
python3 <skill-dir>/scripts/sarif_report.py <file> \
  --split rule --output-dir <directory>
python3 <skill-dir>/scripts/sarif_report.py <file> \
  --split balanced --chunks 4 --output-dir <directory>
```

Strategies: `rule`, `path`, `severity`, `balanced`. Script uses stable filenames
and writes `manifest.json` last. Existing non-empty output requires `--force`.
Manifest keeps the complete file/run mapping even when stdout lists only a
bounded subset.

## Boundaries

- Without `--split`, read file and print report only.
- With `--split`, write only selected output directory.
- Treat SARIF levels as tool evidence, not independent severity validation.
- Inspect representative findings before assigning work or proposing fixes.
