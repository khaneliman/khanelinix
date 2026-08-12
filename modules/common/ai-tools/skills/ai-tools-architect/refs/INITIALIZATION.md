# Repository Instruction Initialization

Use when creating or auditing a repository's `AGENTS.md`, `CLAUDE.md`, path
rules, agents, commands, or skills.

## Workflow

1. Read human contributor canon and the existing instruction chain before
   drafting anything.
2. Inventory which files co-load globally, by directory, by path, or only after
   explicit invocation. Mark duplicate, contradictory, stale, and model-known
   content.
3. Keep root instructions as a short registry: canon links, cross-cutting
   policy, environment quirks, and routing to leaf guidance.
4. Route directory conventions to path-gated rules, reusable workflows to
   skills, narrow context/tool boundaries to agents, and pure one-shot
   transformations to commands. Read the matching component reference before
   editing that surface.
5. Preserve useful existing rules. Do not add vendor banners, generic
   engineering advice, directory listings, or arbitrary line limits.
6. Validate links, loading gates, and precedence. Report what stayed global,
   what moved behind a gate, what was deleted, and any unresolved conflict.
