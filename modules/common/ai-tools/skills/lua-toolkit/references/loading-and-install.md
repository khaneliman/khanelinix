# Loading and Installation

How the plugin loads itself and how users install it.

## Self-Lazy-Load — Don't Rely on the Plugin Manager

Don't rely on a plugin manager (lazy.nvim's `event`/`cmd`/`ft` triggers) to
lazy-load for you. Decide which parts load when, and make the plugin load them:

- **Filetype-specific code** → `ftplugin/<filetype>.lua` (loads only for that
  filetype). Such a plugin may have **no** `plugin/` directory at all (see
  apis-and-keymaps).
- **Everything else** → a small `plugin/<name>.lua` registering commands and
  `<Plug>` mappings, deferring `require()` of the core into those handlers (see
  plugin-architecture). Guard with `vim.g.loaded_<name>`.

This yields sub-millisecond startup, works regardless of how (or whether) the
manager lazy-loads it, and needs no `setup()` call (see configuration).

The entry script does a version guard, a `vim.g.loaded_*` guard, and defers
`require()`; config is read from `vim.g`:

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

## lazy.nvim: Documenting Installation

Users still install via a manager. Because the plugin self-initializes and reads
`vim.g.<plugin>`, the spec stays minimal — no `config`/`opts`/`setup()`:

```lua
-- template only
{ "author/my_plugin.nvim" }
```

To set config through the manager, set `vim.g.<plugin>` in `init`/`config`
rather than calling `setup()`:

```lua
-- template only
{
  "author/my_plugin.nvim",
  init = function()
    vim.g.my_plugin = { strategy = "periodic" }
  end,
}
```

Only document an `opts`/`config`-`setup()` flow if you also expose a `setup()`
wrapper — never as the only way to use the plugin.

## Prefer Native APIs Over Utility Dependencies

Before adding a dependency, check for a native API: `vim.system`/`vim.uv`
(processes / async I/O), `vim.fs` (paths/files), `vim.treesitter`
(parsing/queries), `vim.iter`, `vim.json`, `vim.ringbuf`. Modern Neovim replaces
most of what older helper libraries provided. Don't depend on `plenary.nvim`.

## Dependencies (when genuinely needed)

Declare a `dependencies` entry only when the dependency must be installed _and_
loaded together with the parent. Pure-Lua libraries load on `require()`, so mark
them `lazy = true` to keep them off the startup path:

```lua
-- template only
{
  "author/my_plugin.nvim",
  dependencies = {
    { "author/some-lua-lib.nvim", lazy = true },
  },
}
```

## Build Steps

`build` accepts a Lua function, shell command, or `build.lua`. Long build work
must not block the UI thread:

- lazy.nvim runs build functions in a Lua coroutine; use `coroutine.yield()` to
  emit progress and defer to the next tick.
- Never change global cwd (`vim.api.nvim_set_current_dir()`) in a build: builds
  run concurrently and mutating cwd corrupts other in-flight builds. Use
  absolute paths.
