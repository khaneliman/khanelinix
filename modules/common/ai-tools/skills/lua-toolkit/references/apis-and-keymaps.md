# Public APIs, Commands, Keymaps, and Filetypes

Exposing user-facing entry points and buffer/filetype behavior.

## One Scoped Command with Subcommands

Don't create a command per action (`:MyPluginInstall`, `:MyPluginPrune`, ...).
Expose a single scoped command dispatching subcommands, with completion for
each: `:MyPlugin install`, `:MyPlugin update`.

Register with `nargs = "+"`, parse `opts.fargs`, supply a `complete` function
filtering subcommands by the current prefix.

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
  sub(opts.fargs) -- defer require() into the handler
end, {
  nargs = "+",
  desc = "my_plugin commands",
  complete = function(arg_lead, cmdline)
    -- only complete the first token as a subcommand name
    if cmdline:match("^%s*MyPlugin%s+%S*$") then
      return vim.tbl_filter(function(k)
        return k:find(arg_lead, 1, true) == 1
      end, vim.tbl_keys(subcommands))
    end
    return {}
  end,
})
```

Set `range = true` if subcommands act on a visual selection (via
`opts.range`/`opts.line1`/`opts.line2`). For complex argument parsing,
`mega.cmdparse` reduces boilerplate.

## Keymaps: Provide `<Plug>`, Set No Defaults

Don't create default keymaps (they conflict with user configs) or invent a
keymap-setup DSL. Expose `<Plug>` mappings; let users bind their own keys.

`<Plug>` mappings: one-line user config, safe when the plugin is absent, support
`expr = true`, route by mode via Neovim's C-level mode handling — no hand-rolled
mode checks in the payload.

```lua
-- File: plugin/my_plugin.lua  (template only)
vim.keymap.set("n", "<Plug>(MyPluginAction)", function()
  require("my_plugin.core").execute_action({ mode = "normal" })
end, { desc = "my_plugin: action (normal)" })

vim.keymap.set("x", "<Plug>(MyPluginAction)", function()
  require("my_plugin.core").execute_action({ mode = "visual" })
end, { desc = "my_plugin: action (visual)" })
```

Users bind it themselves; Neovim routes by active mode:

```lua
vim.keymap.set({ "n", "x" }, "<leader>ma", "<Plug>(MyPluginAction)")
```

If you must ship a default binding, gate it on
`vim.fn.hasmapto("<Plug>(...)") == 0` so you never clobber a user mapping — but
prefer no default at all.

## Buffer-Local State and Filetypes

Plugins presenting a UI buffer (file explorers, dashboards, floating
diagnostics) should assign a custom `filetype` for granular user control.

- Set the custom filetype **as late as possible** in buffer init, so `FileType`
  fires only after data structures are ready — letting users' autocommands and
  `ftplugin/` scripts run against a fully realized buffer.

For language-specific behavior on existing filetypes, put logic in
`ftplugin/<lang>.lua`, not a monolithic autocommand block in core init. Override
`$VIMRUNTIME` defaults via `after/ftplugin/<lang>.lua`. Guard re-sourcing with a
buffer-local variable.

```lua
-- File: ftplugin/rust.lua  (template only)
if vim.b.did_my_plugin_rust_setup then
  return
end
vim.b.did_my_plugin_rust_setup = true

local bufnr = vim.api.nvim_get_current_buf()

vim.keymap.set("n", "<Plug>(MyPluginRustAnalyzer)", function()
  require("my_plugin.rust_tools").run_analyzer()
end, { buffer = bufnr, desc = "my_plugin: run analyzer" })
```
