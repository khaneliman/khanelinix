# OKF Memory Reference

## Provider Behavior

Main Codex sessions receive one small startup nudge to read only relevant user
or project OKF scope. The hook never injects memory bodies. Codex subagents skip
all OKF lifecycle processing before bundle reads or state writes; set
`OKF_MEMORY_INCLUDE_SUBAGENTS=1` only for diagnostics.

Claude Code and Antigravity inject no startup context. Routine user turns stay
silent for every provider. Prior memory remains on-demand through scoped bundle
reads. A one-shot Stop audit runs after explicit durable-memory intent or
substantial tool work.

Memory written during a running session is already visible to that agent. Read
the relevant bundle explicitly when an immediate refresh matters.

Planning-with-files optionally owns transient task/session state when persistent
continuity is useful. OKF owns durable user or project knowledge.
Provider-native memory is a secondary mirror, never the sole durable write when
OKF is available.

## Conformance

The bundle follows
[OKF v0.1](https://github.com/GoogleCloudPlatform/knowledge-catalog/blob/main/okf/SPEC.md):

- Every file except `index.md` and `log.md` has non-empty `type:` frontmatter.
- Unrecognized frontmatter keys are valid.
- Links may be bundle-relative absolute paths or relative Markdown links.
- Link meaning comes from surrounding prose.
- Broken links are tolerated.
- No runtime or SDK is required.

## Hermes Boundary

Hermes Agent's frozen snapshots use KV-cache pinning inside its own runtime.
This skill adopts only the curation discipline: bounded local memory that forces
synthesis. Markdown injection does not provide prompt-cache, latency, or
token-cost guarantees.
