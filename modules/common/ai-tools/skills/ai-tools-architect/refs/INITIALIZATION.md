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

## Claude Code and AGENTS.md

Claude Code 2.1.289 loads `AGENTS.md` and `.claude/AGENTS.md` wherever it would
load `CLAUDE.md`, but only when no project `CLAUDE.md` exists at the session
root or above it. A `CLAUDE.md` that only imports `@AGENTS.md` therefore turns
the loader off; delete such shims instead of adding them. The loader reads no
user-level `AGENTS.md`, so user instructions still need `CLAUDE.md` in the
Claude config directory. Do not name reference files `AGENTS.md`: nested ones
load as instructions when Claude reads a sibling file.

Anthropic gates this loader behind a remote flag. When instructions seem
missing, run `claude -p --debug` and look for
`no CLAUDE.md found; AGENTS.md loaded` in the debug log.
