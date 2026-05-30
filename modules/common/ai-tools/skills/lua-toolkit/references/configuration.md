# Configuration UX

User-facing configuration interface and runtime health checks.

## Separate Configuration from Initialization

- **Configuration** — the user's chosen options. Declarable with no side effects
  and no mandatory function call.
- **Initialization** — wiring commands, autocommands, state. Happens
  automatically and lazily (see plugin-architecture), not forced on the user.

## `setup()` Is Not a Gate — Prefer `vim.g.<plugin>`

Don't force `setup()`. Preferred interface is a `vim.g.<plugin>` (or
`vim.b.<plugin>` for buffer-local) namespace table: Vimscript-compatible, no
initialization call, read lazily so users may set it before _or_ after the
plugin loads.

Allow a table or a function returning a table, for lazily-computed config:

```lua
-- User config (no setup() needed):
---@type my_plugin.Opts
vim.g.my_plugin = {
  strategy = "incremental",
  ui = { border = "rounded" },
}
-- or a function, evaluated when the plugin reads it:
vim.g.my_plugin = function()
  return { strategy = "incremental" }
end
```

Read and merge lazily inside the plugin, with type annotations marking the
user-facing table partial and the internal config fully-defaulted:

```lua
-- File: lua/my_plugin/config.lua  (template only)
local M = {}

---@class my_plugin.Config       -- internal: every field non-nil
local default_config = {
  strategy = "incremental",
  ui = {
    border = "rounded",
    icons = true,
    colors = { error = "#ff0000", warn = "#ffff00" }, -- dict: deep-merged
  },
  capabilities = { "formatting", "diagnostics" },       -- list: overwritten
}

--- Resolve user config (table or function) and merge over defaults.
---@return my_plugin.Config
function M.get()
  ---@type my_plugin.Opts | fun():my_plugin.Opts | nil
  local user = vim.g.my_plugin
  if type(user) == "function" then
    user = user()
  end
  local merged = vim.tbl_deep_extend("force", default_config, user or {})
  M.validate(merged)
  return merged
end

return M
```

And the user-facing class, declared partial so all fields are optional:

```lua
---@class (partial) my_plugin.Opts: my_plugin.Config
```

Keep `setup()` only as an optional convenience; never the sole entry point.

## Merge Semantics: `vim.tbl_deep_extend`

`vim.tbl_deep_extend(behavior, ...)` (usually `"force"`) treats the two table
shapes differently:

- **Dictionary-like** (string keys): merged recursively.
- **List-like** (sequential integer keys): opaque, **overwritten** wholesale,
  not concatenated.

Intentional — lists are atomic ordered collections (tool order, flags). Default
`capabilities = { "formatting", "diagnostics" }` + user
`capabilities = { "formatting" }` yields exactly the user's single-item list —
no merge, no dedup.

## Validation: `vim.validate`

Validate the merged table to fail fast with a clear path to the bad field.

The table-spec signature `vim.validate({ name = { value, type } })` is
**deprecated in 0.11** (removed in 1.0): allocates transient tables, slower. Use
the per-argument signature
`vim.validate(name, value, validator, optional_or_msg)`:

```lua
-- File: lua/my_plugin/config.lua (continued) — template only
function M.validate(cfg)
  vim.validate("strategy", cfg.strategy, "string")
  vim.validate("ui_border", cfg.ui.border, "string", true) -- optional
  vim.validate("icons", cfg.ui.icons, "boolean")
  vim.validate("capabilities", cfg.capabilities, "table")
end
```

## Health Checks: `lua/<plugin>/health.lua`

Provide a `:checkhealth` report via `lua/<plugin>/health.lua` using `vim.health`
(`:h vim.health`, `:h health-dev`). The right home for expensive checks you
should _not_ run synchronously in init, including unknown-field/typo detection.
Validate:

- user config correctness (types, unknown keys),
- plugin initialized as expected,
- required Lua dependencies present,
- external (binary) dependencies present.

```lua
-- File: lua/my_plugin/health.lua  (template only)
local M = {}

function M.check()
  vim.health.start("my_plugin")
  if vim.fn.executable("some-cli") == 1 then
    vim.health.ok("`some-cli` found")
  else
    vim.health.error("`some-cli` not found", { "install some-cli and re-run" })
  end
end

return M
```
