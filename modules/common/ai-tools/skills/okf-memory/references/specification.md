# OKF Memory Reference

## Provider Behavior

Claude Code and Codex inject `.okf/MEMORY.local.md` and `.okf/index.md` once at
session start. Other providers should follow the root skill's read order when
project history matters. Concept files remain on-demand for every provider.

Memory written during a running session is already visible to that agent.
External edits become automatic context at the next session start; read the
bundle explicitly when an immediate refresh matters.

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
