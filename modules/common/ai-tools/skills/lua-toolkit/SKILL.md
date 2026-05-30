---
name: lua-toolkit
description: Neovim Lua plugin development playbooks — project architecture, self lazy-loading, vim.g configuration, scoped commands and <Plug> keymaps, health checks, type-safe tooling, busted testing, and LuaRocks distribution. Use when writing or refactoring a Neovim Lua plugin, designing vim.g/setup config, deciding command/keymap APIs, adding checkhealth, configuring lua-ls/luacheck/stylua/LuaCATS, or setting up busted/nlua tests and SemVer LuaRocks releases.
---

# Lua Toolkit

Authoring and refactoring Neovim Lua plugins targeting LuaJIT/Lua 5.1.
Conventions are LuaRocks-first, type-safe, self-lazy-loading, no forced
`setup()`. Neovim-plugin specific; for general embedded Lua, only the tooling
and runtime guardrails transfer.

## Routing (progressive disclosure)

Route to one mode and load only that reference unless work crosses boundaries.
If intent is unclear, ask first.

1. [plugin-architecture.md](references/plugin-architecture.md) — runtimepath
   directory model, `plugin/` vs `lua/` separation, deferred-`require` loading,
   no-runtime-entrypoint plugins, `util.lua` refactoring, global-pollution
   rules, `if jit then ... else` fallback.
2. [configuration.md](references/configuration.md) — `vim.g.<plugin>`
   (table-or-function) config not forced `setup()`, partial LuaCATS config
   classes, dict-vs-list `vim.tbl_deep_extend` behavior, modern `vim.validate`
   (0.11+) signature, `lua/<plugin>/health.lua` checks.
3. [loading-and-install.md](references/loading-and-install.md) —
   self-lazy-loading via `plugin/`+`ftplugin/` (don't rely on the plugin
   manager), minimal lazy.nvim specs, native-API-over-`plenary`, `lazy = true`
   deps, coroutine `build` constraints.
4. [apis-and-keymaps.md](references/apis-and-keymaps.md) — single scoped command
   with `complete`, `<Plug>` mappings with no default keymaps, buffer-local
   state, `ftplugin` vs `after/ftplugin`.
5. [tooling-and-quality.md](references/tooling-and-quality.md) — LuaCATS +
   lua-ls as primary correctness tool, `.luarc.json` (`"Lua 5.1"`), `lua51`
   `.luacheckrc`, stylua baseline.
6. [testing-and-distribution.md](references/testing-and-distribution.md) —
   `busted`+`nlua` (`neorocksTest` for Nix), stable/nightly CI matrix,
   vimcats/panvimdoc generation, SemVer `.rockspec`/`luarocks-tag-release`.

## Core Rules (apply in every mode)

- Target Lua 5.1 / LuaJIT 2.1. Do not use Lua 5.2+ dialect features (new `goto`
  scoping, integer division, native bitwise operators); use `require("bit")` for
  bit ops — Neovim guarantees it even on non-JIT builds.
- Never declare globals. All state, caches, and functions live in `local`
  bindings or the module table returned by the file.
- Separate configuration from initialization. Do not force `setup()`; prefer a
  `vim.g.<plugin>` config table read lazily.
- Self-lazy-load: keep startup work out of `lua/`, use `plugin/`+`ftplugin/`,
  and defer `require()` into command/keymap closures. Don't rely on the plugin
  manager to lazy-load for you.
- Expose one scoped command with subcommand completion, not many commands.
- Expose user-bindable actions as `<Plug>` mappings and ship no default keymaps.
- Prioritize type safety: LuaCATS annotations + lua-ls, gated in CI.
- Distribute on LuaRocks with SemVer; never `0ver`.

## Reference Implementations

Canonical real-world examples: `nvim-best-practices`,
`nvim-lua-nix-plugin-template` (Nix CI), `rustaceanvim`, `neotest-haskell`.

## Cross-Skill Boundaries

- `writing-nix` before editing Nix that packages/wires the plugin (Nixvim,
  `vimUtils` derivations).
- `git-toolkit` for commit strategy and local history surgery.
- `github-toolkit` for PR review comments and CI check triage.
- One-off tooling via `nix shell`/`,` (stylua, luacheck, neovim nightly) over
  persistent lint/test deps.

## Reporting Rules

- Show exact commands, paths, and minimal snippets.
- Label snippets: executed, syntax checked, or template only.
- Separate measured facts (startup time, test output) from design guidance.
- Name the Neovim version when behavior is version-gated (e.g. `vim.validate`
  deprecated in 0.11, removed in 1.0).
