# Trace Forensics

Trace forensics inspects existing profile and trace artifacts. Use this playbook
to analyze offline trace files.

## Supported Formats

- `.cpuprofile`: V8 and Node.js CPU sampling profiles.
- `Trace-*.json.gz`: Chrome DevTools and performance event traces.
- `Spindump.txt`: macOS kernel and user space thread sample dumps.
- Structured JSON and binary profile captures.

## Analysis Steps

1. **Ingest and convert.** Load the raw artifact into a queryable structure,
   such as an SQLite database or structured table.
2. **Traverse call trees.** Query top time sinks and aggregate inclusive versus
   exclusive execution time.
3. **Map symbols.** Resolve symbol names, source file paths, and line numbers.
   State if symbols are missing or stripped.
4. **Diff paired captures.** Compare regression traces against known good
   baseline traces to isolate regressions from background noise.
5. **Flag inconclusive traces.** If the trace lacks relevant symbols or fails to
   capture the reported symptom, report it as inconclusive.
