# Public APIs, Commands, Keymaps, and Filetypes

## One Scoped Command with Subcommands

One command dispatches subcommands (`:MyPlugin install`, `:MyPlugin update`) —
not a command per action. Use `nargs = "+"`, parse `opts.fargs`, supply
`complete` filtering on the first token. Set `range = true` if subcommands act
on visual selection. For complex arg parsing, `mega.cmdparse` reduces
boilerplate.

```lua
-- File: plugin/my_plugin.lua  (template only)
local subcommands = {
  install = function(args) require("my_plugin.core").install(args) end,
  update = function(args) require("my_plugin.core").update(args) end,
}

vim.api.nvim_create_user_command("MyPlugin", function(opts)
  local name = table.remove(opts.fargs, 1)
  local sub = subcommands[name]
  if not sub then
    return vim.notify("MyPlugin: unknown subcommand " .. tostring(name), vim.log.levels.ERROR)
  end
  sub(opts.fargs)
end, {
  nargs = "+",
  desc = "my_plugin commands",
  complete = function(arg_lead, cmdline)
    if cmdline:match("^%s*MyPlugin%s+%S*$") then
      return vim.tbl_filter(function(k) return k:find(arg_lead, 1, true) == 1 end, vim.tbl_keys(subcommands))
    end
    return {}
  end,
})
```

## Keymaps: `<Plug>` Only, No Defaults

Don't create default keymaps. Expose `<Plug>` mappings; let users bind their own
keys. `<Plug>` routes by mode via Neovim's C-level handling — no hand-rolled
mode checks in the payload.

```lua
vim.keymap.set("n", "<Plug>(MyPluginAction)", function()
  require("my_plugin.core").execute_action({ mode = "normal" })
end, { desc = "my_plugin: action (normal)" })

vim.keymap.set("x", "<Plug>(MyPluginAction)", function()
  require("my_plugin.core").execute_action({ mode = "visual" })
end, { desc = "my_plugin: action (visual)" })
```

If a default binding is unavoidable, gate on
`vim.fn.hasmapto("<Plug>(...)") == 0`.

## Buffer-Local State and Filetypes

UI buffers (explorers, dashboards) should set a custom filetype. Set it **as
late as possible** in buffer init so `FileType` fires after data structures are
ready.

For language-specific behavior: `ftplugin/<lang>.lua`, not a monolithic
autocommand in core. Override `$VIMRUNTIME` via `after/ftplugin/<lang>.lua`.
Guard re-sourcing with a buffer-local variable:

```lua
-- File: ftplugin/rust.lua  (template only)
if vim.b.did_my_plugin_rust_setup then return end
vim.b.did_my_plugin_rust_setup = true

local bufnr = vim.api.nvim_get_current_buf()
vim.keymap.set("n", "<Plug>(MyPluginRustAnalyzer)", function()
  require("my_plugin.rust_tools").run_analyzer()
end, { buffer = bufnr, desc = "my_plugin: run analyzer" })
```
