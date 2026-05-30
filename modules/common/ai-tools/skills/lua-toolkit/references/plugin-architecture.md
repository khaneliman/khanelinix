# Plugin Architecture

Directory layout, eager-vs-lazy evaluation, modular refactoring, runtime
guardrails.

## Directory Model

Neovim discovers plugins via `runtimepath`. `lua/` scripts evaluate only when
`require()`d (per-plugin lazy loading).

| Path                  | Evaluation                                                                 |
| --------------------- | -------------------------------------------------------------------------- |
| `plugin/`             | Eager, on startup. Lightweight only: user commands, top-level keymaps.     |
| `lua/<plugin>/`       | On-demand via `require()`. Core implementation. `init.lua` routes modules. |
| `ftplugin/<ft>.lua`   | When a matching filetype opens. Language-specific setup.                   |
| `after/ftplugin/<ft>` | After default `ftplugin/`, so plugin overrides win over `$VIMRUNTIME`.     |
| `doc/`                | Generated Vimdoc `.txt` + tags.                                            |
| `test/`               | Unit/integration tests (native busted).                                    |
| `.stylua.toml`        | StyLua formatter config.                                                   |
| `.luacheckrc`         | Luacheck linter config.                                                    |

Not every plugin has runtime entry points. Adapters/libraries loaded _by another
plugin_ (a Neotest adapter, a null-ls/none-ls source) rather than by Neovim's
runtime have **no** `plugin/` or `ftplugin/` and expose no user commands — their
entire surface is the `lua/` tree the host `require()`s. Don't add a `plugin/`
script just to follow the template.

## Separation of `plugin/` and `lua/`

Core logic is a module under `lua/`. `plugin/` only registers entry points and
**defers** `require()` into closures so the payload loads at first use, not at
startup.

Anti-pattern: top-level `require('my_plugin')` in a `plugin/` script — forces
synchronous parse + compile + eval of the whole plugin during init, inflating
startup.

```lua
-- File: plugin/modern_plugin.lua  (template only)
-- Evaluated eagerly when Neovim parses runtimepath.

if vim.g.loaded_modern_plugin == 1 then
  return
end
vim.g.loaded_modern_plugin = 1

-- Defer the require into the command closure — loads only when invoked.
vim.api.nvim_create_user_command("ModernPluginAction", function(opts)
  require("modern_plugin.core").execute_action(opts.args)
end, {
  nargs = "?",
  desc = "Executes the primary action of the modern plugin",
})

vim.keymap.set("n", "<leader>pa", function()
  require("modern_plugin.core").execute_action()
end, { desc = "Execute Plugin Action" })
```

The `vim.g.loaded_*` guard lets users disable the plugin and prevents
double-sourcing.

## Modular Design

- Avoid a monolithic `util.lua`. As the plugin grows, split into focused modules
  (`string_utils.lua`, `path_utils.lua`, `buffer_utils.lua`).
- A helper with exactly one caller: inline it at the call site instead of
  exporting — improves readability, tightens test boundaries.

One module per responsibility, names that state the responsibility. A real
adapter's module tree:

```text
lua/<plugin>/
├── init.lua      -- entry point; wires the pieces together
├── discover.lua  -- root detection and file-matching rules
├── spec.lua      -- build the run command from an input
├── process.lua   -- run strategy; stream vim.system output
├── results.lua   -- parse output into results/diagnostics
└── parser.lua    -- ensure required tree-sitter grammar is loaded
```

## Runtime Guardrails (LuaJIT vs PUC Lua)

Neovim is built for LuaJIT but may run on standard Lua. Don't assume LuaJIT-only
features (`ffi`, `jit.p`); probe `jit` and degrade gracefully.

```lua
-- File: lua/modern_plugin/math_utils.lua  (template only)
local M = {}

function M.highly_optimized_task(data)
  if jit then
    return M._luajit_process(data) -- hardware-accelerated path
  else
    return M._standard_process(data) -- pure Lua 5.1 fallback
  end
end

return M
```

Exception: bit ops. `require("bit")` is always available — Neovim ships a
C-backed fallback even on non-JIT builds.

## Global Pollution

Variables without `local` land in `_G`: name collisions, unpredictable side
effects, degraded GC. Keep all state, caches, and functions in `local` bindings
or the returned module table.
