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
6. [plenary-migration.md](references/plenary-migration.md) — replace
   `plenary.job`, `plenary.path`, `plenary.scandir`, `plenary.async`,
   `plenary.curl`, `plenary.test_harness`, popup/window helpers, strings,
   filetype, and logging with native Neovim APIs or focused dependencies.
7. [testing-and-distribution.md](references/testing-and-distribution.md) —
   `busted`+`nlua` (`neorocksTest` for Nix), stable/nightly CI matrix,
   vimcats/panvimdoc generation, SemVer `.rockspec`/`luarocks-tag-release`.

## Core Rules (apply in every mode)

Target Lua 5.1 / LuaJIT 2.1, avoid globals, self-lazy-load, prefer lazy
`vim.g.<plugin>` config over forced `setup()`, expose one scoped command plus
`<Plug>` mappings, and gate types with LuaCATS/lua-ls. Read
[core-rules.md](references/core-rules.md) when writing or reviewing plugin code.

## Reference Implementations

Canonical real-world examples: `nvim-best-practices`,
`nvim-lua-nix-plugin-template` (Nix CI), `rustaceanvim`, `neotest-haskell`.

## Cross-Skill Boundaries and Reporting

See [operating-rules.md](references/operating-rules.md).
