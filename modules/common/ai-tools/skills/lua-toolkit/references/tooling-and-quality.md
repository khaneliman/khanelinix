# Tooling and Quality

Static analysis, formatting, type annotations. All tooling targets Lua 5.1 /
LuaJIT. LuaCATS + lua-language-server is the primary correctness tool, not just
a linter.

## Type Safety Is the Priority

LuaCATS annotations + `lua-language-server` catch bugs before runtime — the
highest-leverage quality practice. Supporting tooling: `lazydev.nvim` (dev-time
lua-ls setup), `lua-typecheck-action` (CI), `emmylua-analyzer-rust` / `lux-cli`
(`lx check`, `lx lint`) as analyzer alternatives.

## Luacheck (`.luacheckrc`)

Neovim injects a large global API, so raw analyzers flag `vim` as undefined.
Place `.luacheckrc` at the repo root, declaring `vim` plus busted globals
read-only. Keep it minimal:

```lua
-- File: .luacheckrc  (template only)
ignore = {
  "631", -- max_line_length
  "122", -- read-only field of global variable
}
read_globals = {
  "vim",
  "describe",
  "it",
  "assert",
}
```

This catches variable shadowing, scope leakage, and deprecated API usage at lint
time. Luacheck is secondary to lua-ls; keep it light.

## StyLua (`.stylua.toml`)

StyLua is the standard formatter; it safely parses Lua dialect quirks. Ship a
config so CI can run `stylua --check .` and diffs stay uniform. A common
2-space, single-quote baseline:

```toml
# File: .stylua.toml  (template only)
line_endings = "Unix"
indent_type = "Spaces"
indent_width = 2
quote_style = "AutoPreferSingle"
call_parentheses = "NoSingleTable"
collapse_simple_statement = "Never"
```

> Match an existing repo's stylua config if one is present rather than imposing
> a baseline; consistency within the repo wins.

## LuaCATS Annotations

Lua lacks static types; LuaCATS annotations are the contract that lets `lua_ls`
provide completion, parameter validation, and inline docs. Document data
crossing module boundaries with `@param`/`@return` (and `@class`, `@field`,
`@type` as needed).

```lua
-- template only
---@class ModernPlugin.Action
---@field mode "normal"|"visual"

--- Execute the primary action.
---@param opts ModernPlugin.Action
---@return boolean ok
function M.execute_action(opts) end
```

These annotations also feed automated Vimdoc generation (see
testing-and-distribution).

## `.luarc.json` and lua-ls as a CI Gate

`.luarc.json` configures `lua-language-server` to understand Neovim's APIs and
the plugin's deps. Set `runtime.version` to `"Lua 5.1"` (not `"LuaJIT"`) so
lua-ls flags LuaJIT-only usage that would break non-JIT builds, and point
`workspace.library` at `$VIMRUNTIME` and any test/runtime deps:

```jsonc
// File: .luarc.json  (template only)
{
  "runtime.version": "Lua 5.1",
  "workspace.library": ["$VIMRUNTIME"]
}
```

Prefer generating it from the dev environment so it stays in sync and can be
git-ignored: a flake `shellHook`, `lazydev.nvim`, `.neoconf.json` (neoconf), or
`lux`/`lx` all emit the library paths, including resolved test-dependency `src`
paths so lua-ls resolves `busted`/`nlua` symbols.

Treat lua-ls type diagnostics as a required CI check, separate from tests: a
green test suite is **not** sufficient if type diagnostics fail. Run lua-ls in
CI (commonly via a pre-commit hook) alongside luacheck and stylua.

## One-off Tooling

In this repo, run formatters/linters via `nix shell` or `,` rather than adding
persistent lint deps:

```bash
nix run nixpkgs#stylua -- --check .
nix run nixpkgs#lua51Packages.luacheck -- lua plugin test
```
