# Tooling and Quality

All tooling targets Lua 5.1 / LuaJIT. LuaCATS + lua-ls is the primary
correctness tool, not just a linter.

## Priority: LuaCATS + lua-ls

Catch bugs before runtime. Supporting tools: `lazydev.nvim` (dev-time lua-ls
setup), `lua-typecheck-action` (CI), `emmylua-analyzer-rust` / `lux-cli`
(`lx check`, `lx lint`) as alternatives.

Annotate data crossing module boundaries:

```lua
---@class ModernPlugin.Action
---@field mode "normal"|"visual"

---@param opts ModernPlugin.Action
---@return boolean ok
function M.execute_action(opts) end
```

## `.luarc.json` — CI Gate

Set `runtime.version` to `"Lua 5.1"` (not `"LuaJIT"`) — lua-ls then flags
LuaJIT-only usage that breaks non-JIT builds:

```jsonc
{ "runtime.version": "Lua 5.1", "workspace.library": ["$VIMRUNTIME"] }
```

Generate from dev env (flake `shellHook`, `lazydev.nvim`, `lux`) so it stays in
sync and can be git-ignored; generated paths include `busted`/`nlua` src so
lua-ls resolves test symbols.

**Green test suite is not sufficient** if lua-ls type diagnostics fail. Run
lua-ls in CI alongside luacheck and stylua.

## Luacheck (`.luacheckrc`)

Secondary to lua-ls; keep it minimal. Declare `vim` + busted globals read-only:

```lua
-- File: .luacheckrc  (template only)
ignore = { "631", "122" }
read_globals = { "vim", "describe", "it", "assert" }
```

## StyLua (`.stylua.toml`)

Match an existing repo's stylua config if present — consistency wins. Baseline:

```toml
line_endings = "Unix"
indent_type = "Spaces"
indent_width = 2
quote_style = "AutoPreferSingle"
call_parentheses = "NoSingleTable"
collapse_simple_statement = "Never"
```

## One-off Tooling

Run via `nix shell` or `,` — don't add persistent lint deps:

```bash
nix run nixpkgs#stylua -- --check .
nix run nixpkgs#lua51Packages.luacheck -- lua plugin test
```
