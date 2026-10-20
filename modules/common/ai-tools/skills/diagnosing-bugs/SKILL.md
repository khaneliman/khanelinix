---
name: diagnosing-bugs
description: "General software bug diagnosis for broken, failing, throwing, flaky, or incorrect behavior. Read-only by default. Inside a requested fix, engineering-workflow owns the lifecycle. Use performance-forensics for latency, CPU, throughput, I/O, contention, or traces."
license: Complete terms in LICENSE
---

# Diagnosing Bugs

Use this skill to establish why general software behavior fails. Diagnosis-only
work is read-only by default. If the user requests a fix, use this method inside
the `engineering-workflow` Ground phase and return control to that lifecycle.

## Safety Boundary

- Redact secrets from commands, output, logs, traces, and fixtures.
- Do not create persistent files, edit source, alter the caller's working copy,
  or change external state during diagnosis-only work without explicit
  authority.
- Before a remote probe, confirm the user placed the target in scope and the
  endpoint or interaction contract is non-mutating.
- Run throwaway harnesses and mutation-capable history probes only in isolated
  temporary directories.
- If temporary instrumentation is authorized, tag it with one unique
  `[DEBUG-<id>]` prefix and remove it before handoff.

## Diagnosis Contract

Choose one evidence path. Read [diagnosis-loop.md](references/diagnosis-loop.md)
for the selected path's detail:

1. **Reproduction, preferred:** run a focused command that detects the user's
   exact symptom. Reuse it to test the cause and verify a requested fix. Minimize
   the reproduction only as far as needed to isolate the relevant uncertainty.
2. **Source or contract evidence:** when the defect follows conclusively from
   source, a schema, documentation, or an input/output contract, establish the
   mismatch directly. State what this proves and what still needs runtime
   confirmation. Do not claim an unexecuted reproduction or fix check.

Start with the best-supported explanation and a check that could disprove it.
Compare alternative hypotheses when the evidence is ambiguous or a check fails;
do not invent a quota of alternatives for an established mismatch.

A caller may strengthen either path, for example by requiring runtime
reproduction for a timing bug or release acceptance. Honor that requirement
without imposing it on every diagnosis. When neither path provides sufficient
evidence, report the gap and request only the access or artifact needed to
resolve it. Do not replace missing evidence with speculation.

For diagnosis-only work, stop after the evidence report. For a requested fix,
return the evidence and supported cause to `engineering-workflow`.
That lifecycle owns implementation, regression verification, review, and
handoff.
