# Plugin Architecture

## Directory Model

| Path                  | Evaluation                                                                 |
| --------------------- | -------------------------------------------------------------------------- |
| `plugin/`             | Eager, on startup. Lightweight only: user commands, top-level keymaps.     |
| `lua/<plugin>/`       | On-demand via `require()`. Core implementation. `init.lua` routes modules. |
| `ftplugin/<ft>.lua`   | When a matching filetype opens. Language-specific setup.                   |
| `after/ftplugin/<ft>` | After default `ftplugin/`, so plugin overrides win over `$VIMRUNTIME`.     |
| `doc/`                | Generated Vimdoc `.txt` + tags.                                            |
| `test/`               | Unit/integration tests (native busted).                                    |

Adapters/libraries loaded by another plugin (Neotest adapter, null-ls source)
have **no** `plugin/` or `ftplugin/` — expose no user commands, only the `lua/`
tree. Don't add `plugin/` just to follow the template.

## `plugin/` vs `lua/` Separation

`plugin/` registers entry points only. Defer `require()` into closures so the
payload loads at first use, not at startup. Guard with `vim.g.loaded_*` to allow
user disabling and prevent double-sourcing.

```lua
-- File: plugin/modern_plugin.lua  (template only)
if vim.g.loaded_modern_plugin == 1 then return end
vim.g.loaded_modern_plugin = 1

vim.api.nvim_create_user_command("ModernPluginAction", function(opts)
  require("modern_plugin.core").execute_action(opts.args)
end, { nargs = "?", desc = "Executes the primary action of the modern plugin" })
```

Anti-pattern: top-level `require('my_plugin')` in `plugin/` — forces synchronous
parse+compile+eval of the whole plugin at startup.

## Modular Design

- Split `util.lua` into focused modules as the plugin grows (`string_utils.lua`,
  `path_utils.lua`).
- A helper with exactly one caller: inline it instead of exporting.
- One module per responsibility. Example tree:

```text
lua/<plugin>/
├── init.lua      -- wires the pieces together
├── discover.lua  -- root detection / file-matching
├── spec.lua      -- build the run command
├── process.lua   -- run strategy; stream vim.system output
├── results.lua   -- parse output into results/diagnostics
└── parser.lua    -- ensure tree-sitter grammar is loaded
```

## Runtime Guardrails

Probe `jit` and degrade gracefully — don't assume LuaJIT-only features (`ffi`,
`jit.p`):

```lua
if jit then
  return M._luajit_process(data)
else
  return M._standard_process(data)
end
```

Exception: `require("bit")` is always available — Neovim ships a C-backed
fallback even on non-JIT builds.

## Global Pollution

Never declare globals. All state, caches, and functions in `local` bindings or
the returned module table.
