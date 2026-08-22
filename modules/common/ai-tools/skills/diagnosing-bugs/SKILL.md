---
name: diagnosing-bugs
description: "General software bug diagnosis for broken, failing, throwing, flaky, or incorrect behavior. Read-only by default. Inside a requested fix, engineering-workflow owns the lifecycle. Use performance-forensics for latency, CPU, throughput, I/O, contention, or traces."
license: Complete terms in LICENSE
---

# Diagnosing Bugs

Use this skill to establish why general software behavior fails. Diagnosis-only
work is read-only by default. If the user requests a fix, use this method inside
the `engineering-workflow` Ground phase and return control to that lifecycle.

Use `performance-forensics` for measured performance problems. Use
`memory-profiler` for leaks, out-of-memory errors, or heap fragmentation.

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

Read [diagnosis-loop.md](references/diagnosis-loop.md), then:

1. Build and run one fast feedback command that can detect the user's exact
   symptom. Record its red result.
2. Minimize the reproduction one element at a time. Stop when every remaining
   element is load-bearing.
3. Rank three to five falsifiable hypotheses. State one observable prediction
   for each hypothesis.
4. Run one-variable probes against those predictions. Prefer debugger or REPL
   inspection over broad logging.
5. State the supported cause, rejected hypotheses, evidence, and residual
   uncertainty.

If no red-capable loop is possible, report each attempted route and request the
smallest missing access, redacted artifact, or instrumentation authority. Do not
replace the missing signal with speculation.

For diagnosis-only work, stop after the evidence report. For a requested fix,
return the minimized reproduction and supported cause to `engineering-workflow`.
That lifecycle owns implementation, regression verification, review, and
handoff.

## Attribution

Adapted from Matt Pocock's diagnosing-bugs skill. Prose is original. Upstream
terms are in [LICENSE](LICENSE).
