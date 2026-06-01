# Lua Toolkit Core Rules

Use when writing or reviewing Neovim Lua plugin code.

## Runtime

- Target Lua 5.1 / LuaJIT 2.1.
- Do not use Lua 5.2+ dialect features: new `goto` scoping, integer division,
  native bitwise operators.
- Use `require("bit")` for bit ops; Neovim provides it even on non-JIT builds.

## State And Loading

- Never declare globals.
- Keep state, caches, and functions in `local` bindings or returned module
  table.
- Keep startup work out of `lua/`.
- Use `plugin/` + `ftplugin/` and defer `require()` into command/keymap
  closures.
- Do not rely on plugin manager lazy-loading as primary design.

## Configuration

- Separate configuration from initialization.
- Do not force `setup()`.
- Prefer lazily read `vim.g.<plugin>` config table or function.

## API

- Expose one scoped command with subcommand completion, not many commands.
- Expose user-bindable actions as `<Plug>` mappings.
- Ship no default keymaps.

## Quality And Distribution

- Prioritize LuaCATS annotations plus lua-ls.
- Gate type checks in CI.
- Distribute on LuaRocks with SemVer; never `0ver`.
