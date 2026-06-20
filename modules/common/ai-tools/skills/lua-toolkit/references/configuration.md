# Configuration UX

## `vim.g.<plugin>` — Not `setup()`

Don't force `setup()`. Use `vim.g.<plugin>` (or `vim.b.<plugin>` for
buffer-local): Vimscript-compatible, no init call, read lazily (users may set
before or after plugin loads). Accept a table or a function returning a table.

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

---@class (partial) my_plugin.Opts: my_plugin.Config

---@return my_plugin.Config
function M.get()
  ---@type my_plugin.Opts | fun():my_plugin.Opts | nil
  local user = vim.g.my_plugin
  if type(user) == "function" then user = user() end
  local merged = vim.tbl_deep_extend("force", default_config, user or {})
  M.validate(merged)
  return merged
end

return M
```

Keep `setup()` only as an optional convenience; never the sole entry point.

## Merge Semantics: `vim.tbl_deep_extend`

- **Dict keys** (string): merged recursively.
- **List keys** (sequential int): **overwritten** wholesale, not concatenated.

`capabilities = {"formatting","diagnostics"}` default + user
`capabilities = {"formatting"}` yields exactly `{"formatting"}` — no merge.

## Validation: `vim.validate`

Table-spec `vim.validate({ name = { value, type } })` is **deprecated in 0.11,
removed in 1.0**. Use the per-argument signature:

```lua
vim.validate("strategy", cfg.strategy, "string")
vim.validate("ui_border", cfg.ui.border, "string", true) -- optional
vim.validate("capabilities", cfg.capabilities, "table")
```

## Health Checks: `lua/<plugin>/health.lua`

Home for expensive checks (unknown-field/typo detection, binary deps) that must
not run synchronously in init. Validate: config types/unknown keys, plugin init
state, Lua deps, external binaries.

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
