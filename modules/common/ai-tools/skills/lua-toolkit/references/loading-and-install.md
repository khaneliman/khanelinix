# Loading and Installation

## Self-Lazy-Load — Don't Rely on the Plugin Manager

Don't rely on `event`/`cmd`/`ft` triggers in the manager. Make the plugin load
itself:

- **Filetype-specific** → `ftplugin/<filetype>.lua`. Plugin may have no
  `plugin/` at all.
- **Everything else** → `plugin/<name>.lua` registers commands + `<Plug>`
  mappings, defers `require()` into handlers, guards with `vim.g.loaded_<name>`.

Yields sub-millisecond startup, works regardless of manager, needs no `setup()`.

```lua
-- File: ftplugin/rust.lua  (template only)
if vim.fn.has("nvim-0.12") ~= 1 then
  vim.notify_once("my_plugin requires Neovim 0.12+", vim.log.levels.ERROR)
  return
end

---@type my_plugin.Config
local config = require("my_plugin.config").get()

if not vim.g.loaded_my_plugin then
  vim.g.loaded_my_plugin = true
  -- one-time global setup (lsp handlers, autocommands) using `config`
end
```

## lazy.nvim: Minimal Install Spec

Plugin self-initializes and reads `vim.g.<plugin>`, so the spec needs no
`config`/`opts`/`setup()`:

```lua
{ "author/my_plugin.nvim" }
-- or with config:
{ "author/my_plugin.nvim", init = function() vim.g.my_plugin = { strategy = "periodic" } end }
```

Only document `setup()` flow if you also expose a `setup()` wrapper.

## Prefer Native APIs Over Utility Dependencies

Check native first: `vim.system`/`vim.uv` (processes/async I/O), `vim.fs`
(paths/files), `vim.treesitter`, `vim.iter`, `vim.json`, `vim.ringbuf`. Don't
depend on `plenary.nvim`.

## Dependencies

Pure-Lua libraries load on `require()` — mark `lazy = true` to keep them off the
startup path:

```lua
{ "author/some-lua-lib.nvim", lazy = true }
```

## Build Steps

lazy.nvim runs build functions in a coroutine. Use `coroutine.yield()` for
progress. Never call `vim.api.nvim_set_current_dir()` in a build — runs
concurrently, mutating cwd corrupts other in-flight builds. Use absolute paths.
