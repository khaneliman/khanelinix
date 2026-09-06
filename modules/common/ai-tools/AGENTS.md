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
- `CLAUDE.md`: sibling `AGENTS.md` import only; auto-loads as in-repo project
  memory for this subtree
- `codex.md`: Codex-only delegation and retry addendum
- `permissions.nix`: shared command and MCP permission catalog
- `skills/multi-provider-sdlc/references/model-routing.json`: canonical semantic
  model policy, gateway catalog, task routes, and quota pools
- `model-routing.nix`: validated Nix adapter for canonical routing policy
- `agents.nix`: semantic worker capabilities and provider renderers
- `agents/shared/worker-core.md`: universal child-worker boundaries and quality
  contract composed into every provider agent
- `marketplace/`: portable publication catalog, native marketplace validation,
  tests, and install documentation
- `skills/`: canonical on-demand workflows; keep root playbooks lean and route
  detail into references/scripts
- `skill-routing/`: deterministic provider gates for verified missed routes
- `planning-with-files/`: vendored provider adapters and explicit planning
  commands; `skills/planning-with-files/` owns the canonical optional workflow
- `okf-memory/`: deterministic cross-provider durable-memory hooks

## Change Boundaries

- Change shared behavior once at canonical source, then verify every renderer or
  consumer affected by that source.
- Published skill directories are native plugin roots. Maintain content only
  under `skills/`; do not create copied marketplace payloads. Follow
  `marketplace/README.md` for version updates and validation.
- Keep prompt changes separate from workflow, permission, hook, and generated
  provider changes when each can stand alone.
- Do not hand-edit deployed files under user config; change repository source
  that Home Manager installs.
