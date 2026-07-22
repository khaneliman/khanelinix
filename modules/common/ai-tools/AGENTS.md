# AI Tool Integration

## Routing

- `default.nix` is central registry and provider router. Downstream tool modules
  consume its exports instead of rebuilding skill, command, agent, hook, or
  policy lists.
- `base.md` contains only cross-repository, cross-provider behavior that should
  always load. Keep khanelinix-specific guidance in repository `AGENTS.md`
  files.
- Keep provider-only behavior in provider adapters such as `CLAUDE.md` and
  `codex.md`.
- Treat vendored provider copies under `planning-with-files/` as upstream
  artifacts unless task explicitly targets them.

## Source Map

- `base.md`: always-loaded behavior shared by configured coding agents
- `CLAUDE.md`: sibling `AGENTS.md` import plus Claude-only delivery addendum
- `codex.md`: Codex-only delegation and retry addendum
- `permissions.nix`: shared command and MCP permission catalog
- `agents.nix`: canonical bounded-worker definitions plus provider renderers
- `skills/`: canonical on-demand workflows; keep root playbooks lean and route
  detail into references/scripts
- `planning-with-files/`: vendored provider adapters and explicit planning
  commands; `skills/planning-with-files/` owns the canonical optional workflow
- `okf-memory/`: deterministic cross-provider durable-memory hooks

## Change Boundaries

- Change shared behavior once at canonical source, then verify every renderer or
  consumer affected by that source.
- Keep prompt changes separate from workflow, permission, hook, and generated
  provider changes when each can stand alone.
- Do not hand-edit deployed files under user config; change repository source
  that Home Manager installs.
