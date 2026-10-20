# Diagnosis Loop

## Select Evidence

Prefer an exact-symptom reproduction because it can check both the cause and a
fix. Use direct source or contract evidence for a conclusive mismatch when
reproduction would add little evidence or is unavailable. A caller's explicit
acceptance criteria can require stronger evidence than this default.

## Reproduction Path

Choose the smallest unattended command that reaches the real failure path. A
focused test, CLI fixture, HTTP request, browser script, trace replay, throwaway
harness, fuzz loop, bisect command, or differential comparison can provide the
signal.

Classify side effects before running the command. A remote request or browser
interaction requires an in-scope target and a documented non-mutating contract.
Explicit diagnosis authority does not authorize state-changing requests,
instrumentation, or production writes. Put throwaway harnesses, trace replays
that write state, and mutation-capable history probes in a fresh temporary
directory. Do not run a bisect that rewrites the caller's working copy.

The command is ready only when all conditions hold:

- It has already run and produced the reported failure.
- Its assertion matches the user's symptom, not a nearby error.
- Repeated runs give the same verdict. For a flaky bug, record a high and stable
  reproduction rate.
- It runs fast enough to use after every probe.
- It runs without unstructured human interaction.
- It preserves the caller's working copy and external state unless the user
  separately authorized the exact mutation.

If the loop needs a secret, read it from the environment. Do not print it or
store it in a fixture.

### Minimize When Needed

Remove one input, caller, configuration value, dependency, data item, or action.
Rerun the feedback command after each removal. Stop when the remaining scenario
isolates the cause well enough to distinguish explanations and verify the fix.
An upstream bug report or difficult fuzz failure may warrant further reduction;
an already decisive trace does not require exhaustive minimization.

## Source or Contract Path

Identify the owning source, schema, documentation, or input/output contract and
the code or configuration that contradicts it. Trace the affected caller so the
mismatch is demonstrated rather than inferred from a similar-looking example.
Use a focused contract check when available. Separate the established defect
from runtime effects that have not been exercised.

If runtime confirmation remains necessary for the question or the caller's
acceptance criteria, name that gap. Request access only when it would resolve
the gap; do not build a harness solely to satisfy a diagnosis template.

## Rank Hypotheses

Start with the best-supported hypothesis and the cheapest decisive check. When
several explanations remain plausible, compare them by evidence and cost to
falsify. Use this format when it helps make a prediction explicit:

```text
If <cause> is responsible, then <one controlled change or observation> will
produce <specific result>.
```

Discard a hypothesis that has no observable prediction. User domain knowledge
can change the ranking, but it does not replace a probe.

## Probe One Variable

Map each probe to one prediction. Change one variable. Record command, result,
and hypothesis status. Prefer direct state inspection. If logging is necessary,
log only the boundary that separates competing hypotheses and use one unique
`[DEBUG-<id>]` prefix.

For nondeterministic failures, first raise and measure reproduction rate with a
pinned seed, repeated runs, controlled load, or narrowed timing window. Do not
interpret a single green run as disproof.

## Close the Loop

For a diagnosis-only request, report:

- exact symptom and the selected evidence path
- feedback command and reproduction, or the demonstrated source/contract mismatch
- supported cause and evidence
- rejected hypotheses and their disproof
- missing evidence and residual uncertainty
- temporary instrumentation status

For a requested fix, preserve the original unminimized command when one exists.
Convert a reproduction into a regression test only at a seam that exercises the
real failure pattern. After implementation, rerun the original signal and any
added regression test, or check the source/contract mismatch that established
the defect. Report any remaining runtime gap. Search for the debug prefix and
remove all temporary instrumentation.
