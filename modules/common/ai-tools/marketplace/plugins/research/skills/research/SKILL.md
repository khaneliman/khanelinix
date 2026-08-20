---
name: research
description: "Investigate a question with high-trust primary sources and return a cited answer. Use for external research, official documentation, specifications, APIs, or first-party source code. Default to read-only answers; write a repository artifact only when explicitly requested. Do not use for repository structure or rationale/history questions; use how or why."
---

# Research

Use this skill for external fact-finding that needs primary-source evidence.

## Boundaries

- Read-only answer by default. Do not create or edit files without an explicit
  request for a repository artifact.
- Prefer official documentation, specifications, source code, and first-party
  APIs. Trace each material claim to the source that owns it.
- Use `how` for repository structure or runtime behavior. Use `why` for
  motivation, historical decisions, regressions, or rationale.
- Keep source access and interpretation separate. Mark uncertainty and
  conflicting primary sources.
- Do not require a provider-specific browser, agent, or citation format.

## Workflow

1. Define the question, scope, date boundary, and required output.
2. Discover and inspect the smallest sufficient set of primary sources.
3. Build a claim-to-source map while researching. Record access dates when
   source state can change.
4. Return a concise answer with citations, limitations, and unresolved facts.
5. If the user explicitly requests a repository artifact, read
   [research-method.md](references/research-method.md), write one cited artifact
   at the requested path, and verify its links and scope.

Do not silently turn research into implementation, planning, or an ADR.
