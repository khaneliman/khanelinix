---
name: lua-toolkit
description: Create, refactor, test, or release Neovim Lua plugins; assess Lua 5.1-5.5 compatibility and migrate standalone or embedded Lua programs.
---

# Lua Toolkit

For Neovim plugins, target LuaJIT/Lua 5.1 with LuaRocks-first distribution,
LuaCATS types, self-lazy-loading, and no forced `setup()`. For standalone or
embedded programs, provide Lua version migration and compatibility verification
without imposing Neovim architecture or APIs.

## Routing (progressive disclosure)

Route to one mode and load only that reference unless work crosses boundaries.
Identify the actual interpreter or embedding host and the versions the project
must retain before choosing syntax, library replacements, or checks.

- **Lua version migration or compatibility audit:** read
  [lua-version-migration.md](references/lua-version-migration.md), then
  [lua-compatibility-verification.md](references/lua-compatibility-verification.md)
  for runnable checks and evidence requirements. Cover every intervening
  boundary from the starting version to 5.5. Keep Neovim/LuaJIT support when
  required; installing standalone Lua 5.5 does not upgrade an embedding host.
- **Neovim plugin work:** select the relevant reference below. These modes
  retain their Lua 5.1 target and plugin-specific conventions.

1. [plugin-architecture.md](references/plugin-architecture.md): runtimepath
   directory model, `plugin/` vs `lua/` separation, deferred-`require` loading,
   no-runtime-entrypoint plugins, `util.lua` refactoring, global-pollution
   rules, `if jit then ... else` fallback.
2. [configuration.md](references/configuration.md): `vim.g.<plugin>`
   (table-or-function) config not forced `setup()`, partial LuaCATS config
   classes, dict-vs-list `vim.tbl_deep_extend` behavior, modern `vim.validate`
   (0.11+) signature, `lua/<plugin>/health.lua` checks.
3. [loading-and-install.md](references/loading-and-install.md):
   self-lazy-loading via `plugin/`+`ftplugin/` (don't rely on the plugin
   manager), minimal lazy.nvim specs, native-API-over-`plenary`, `lazy = true`
   deps, coroutine `build` constraints.
4. [apis-and-keymaps.md](references/apis-and-keymaps.md): single scoped command
   with `complete`, `<Plug>` mappings with no default keymaps, buffer-local
   state, `ftplugin` vs `after/ftplugin`.
5. [tooling-and-quality.md](references/tooling-and-quality.md): LuaCATS + lua-ls
   as primary correctness tool, `.luarc.json` (`"Lua 5.1"`), `lua51`
   `.luacheckrc`, stylua baseline.
6. [plenary-migration.md](references/plenary-migration.md): replace
   `plenary.job`, `plenary.path`, `plenary.scandir`, `plenary.async`,
   `plenary.curl`, `plenary.test_harness`, popup/window helpers, strings,
   filetype, and logging with native Neovim APIs or focused dependencies.
7. [testing-and-distribution.md](references/testing-and-distribution.md):
   `busted`+`nlua` (`neorocksTest` for Nix), stable/nightly CI matrix,
   vimcats/panvimdoc generation, SemVer `.rockspec`/`luarocks-tag-release`.

## Neovim Plugin Rules

Target Lua 5.1 / LuaJIT 2.1, avoid globals, self-lazy-load, prefer lazy
`vim.g.<plugin>` config over forced `setup()`, expose one scoped command plus
`<Plug>` mappings, and gate types with LuaCATS/lua-ls. Read
[core-rules.md](references/core-rules.md) when writing or reviewing plugin code.

## Reference Implementations

Canonical real-world examples: `nvim-best-practices`,
`nvim-lua-nix-plugin-template` (Nix CI), `rustaceanvim`, `neotest-haskell`.

## Cross-Skill Boundaries and Reporting

See [operating-rules.md](references/operating-rules.md).
