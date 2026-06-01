# Lua Toolkit Operating Rules

Use for cross-skill routing and reporting.

## Cross-Skill Boundaries

- Use `writing-nix` before editing Nix that packages/wires plugin: Nixvim,
  `vimUtils` derivations, overlays, or flake outputs.
- Use `git-toolkit` for commit strategy and local history surgery.
- Use `github-toolkit` for PR review comments and CI check triage.
- Prefer one-off tooling through `nix shell` or `,` for stylua, luacheck, or
  Neovim nightly over persistent lint/test dependencies unless project already
  owns them.

## Reporting Rules

- Show exact commands, paths, and minimal snippets.
- Label snippets: executed, syntax checked, or template only.
- Separate measured facts such as startup time/test output from design guidance.
- Name Neovim version when behavior is version-gated; example: `vim.validate`
  deprecated in 0.11 and removed in 1.0.
