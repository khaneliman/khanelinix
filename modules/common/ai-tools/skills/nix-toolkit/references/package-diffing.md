# Package Diffing

## Deterministic First Pass

Compare any two Nix installables with the Python helper:

```bash
python3 "<path-to-skill>/scripts/package_diff_report.py" \
  --repo . \
  --before 'nixpkgs#hello' \
  --after '.#hello'
```

Helper builds with `--no-link`, `--no-update-lock-file`, and
`--no-write-lock-file`; it never creates checkout result links or modifies the
lock file. It hashes regular files, compares path metadata and recursive
closures, bounds large lists, and emits stable JSON. Use `--format text` for a
compact summary or `--no-file-hashes` for a cheaper metadata-only pass.

Add `--diffoscope` only after file and closure evidence warrants deeper work.
Diffoscope writes its temporary report outside checkout; helper returns a
bounded excerpt with store hashes normalized. Missing diffoscope is a hard error
instead of a silent skip.

For revision comparisons, pass immutable or explicitly selected installables.
Prefer fixed revisions over moving branches when result must be reproducible.

## Interpretation

- Same file list with changed hashes: inspect content or generated metadata.
- Hash-only store-path drift: distinguish rebuild drift from behavior change.
- Timestamp-only archive drift: inspect `SOURCE_DATE_EPOCH` and archive member
  ordering.
- ELF differences: compare closure/reference changes before assuming source
  changes.
- Fonts, icons, wheels, and jars: inspect generated indexes and archive order.

## Reporting Checklist

- Compared installables, source revisions, and system.
- Comparison method and whether file hashing or diffoscope ran.
- Byte-identical, file-list different, or structurally different outputs.
- Largest or riskiest changed paths.
- Closure size and dependency changes.
