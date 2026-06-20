# Lua Toolkit Core Rules

## Runtime

- Target Lua 5.1 / LuaJIT 2.1. No 5.2+ dialect: no new `goto` scoping, no
  integer division `//`, no native bitwise operators.
- `require("bit")` for bit ops — always available, even non-JIT builds.

## State And Loading

- Never declare globals. State/caches/functions in `local` bindings or returned
  module table.
- No startup work in `lua/`. Use `plugin/` + `ftplugin/`; defer `require()` into
  command/keymap closures.
- Do not rely on plugin manager lazy-loading as primary design.

## Configuration

- Separate configuration from initialization.
- No forced `setup()`. Prefer lazily read `vim.g.<plugin>` config table or
  function.

## API

- One scoped command with subcommand completion; not one command per action.
- User-bindable actions as `<Plug>` mappings. Ship no default keymaps.

## Quality And Distribution

- LuaCATS annotations + lua-ls as primary correctness tool. Gate type checks in
  CI.
- Distribute on LuaRocks with SemVer; never `0ver`.
