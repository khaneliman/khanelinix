# Plenary Migration

Goal: native APIs first. Plenary upstream is no longer actively maintained.

## Migration Rules

- No new `plenary.nvim` usage.
- Target Neovim 0.10+ for `vim.system`. Set minimum version accordingly.
- Remove plenary from install docs, lazy.nvim specs, rockspec deps, Nix deps,
  and CI after last `require("plenary.*")` is gone.
- Schedule UI mutations (`vim.schedule`) from async callbacks before touching
  buffers, windows, extmarks, or notifications.

## Replacement Map

| Plenary module                             | Replacement                                                                                     | Notes                                                                                             |
| ------------------------------------------ | ----------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------- |
| `plenary.job`                              | `vim.system()`                                                                                  | Async callback or `:wait()`. `{ text = true }` normalizes output; `{ timeout = ms }` bounds jobs. |
| `plenary.path`                             | `vim.fs.joinpath()`, `vim.fs.abspath()`, `vim.fs.basename()`, `vim.fs.dirname()`, `vim.fs.rm()` | Keep paths as strings; avoid `Path:new()` objects.                                                |
| `plenary.scandir`                          | `vim.fs.dir()`, `vim.fs.find()`                                                                 | Prefer lazy iterators. `vim.uv.fs_scandir` only for custom async traversal.                       |
| `plenary.async`                            | native callbacks → vendored coroutine helper → `nvim-nio` → `coop.nvim`                         | Pick smallest model. Don't add `nvim-nio` for one job callback.                                   |
| `plenary.curl`                             | `vim.system({ "curl", ... })`                                                                   | Focused HTTP lib only when plugin owns reusable HTTP concerns (auth, retry, multipart).           |
| `plenary.test_harness`, `plenary.busted`   | `busted` + `nlua`; `mini.test` for isolated child-process tests                                 | See testing-and-distribution for `neorocksTest`.                                                  |
| `plenary.popup`, `plenary.window`          | `vim.api.nvim_open_win()` or `nui.nvim`                                                         | Native float for simple UI; `nui.nvim` for layouts, prompts, trees.                               |
| `plenary.strings`                          | `vim.str_byteindex()`, `vim.str_utfindex()`, `vim.fn.strdisplaywidth()`                         | Use core UTF helpers for byte/char offsets.                                                       |
| `plenary.filetype`                         | `vim.filetype`                                                                                  | Native filetype detection and registration.                                                       |
| `plenary.log`                              | `vim.notify()` for user-facing; minimal local logger for file logs                              | Keep file logging opt-in; avoid on hot paths.                                                     |
| `plenary.context_manager`, `plenary.class` | plain Lua functions/metatables                                                                  | Direct control flow and simple tables.                                                            |

## `vim.system` Key Patterns

Sync: `vim.system({...}, { text = true, timeout = 5000 }):wait()` — check
`result.code`, use `vim.trim(result.stdout)`.

Streaming: bind `stdout`/`stderr` callbacks; wrap body in `vim.schedule`. Use
`vim.uv.spawn()` only when `vim.system()` can't express required
handle/stdio/lifecycle.

Path ops — keep string-based:
`vim.fs.joinpath(vim.fn.stdpath("cache"), "my_plugin", "state.json")`. For large
tree scans, process `vim.fs.dir()` incrementally — don't build one huge table
first.

`plenary.curl` JSON replacement:
`vim.system({"curl","--silent","--fail-with-body","-X","POST","-H","content-type: application/json","--data-binary","@-",endpoint}, { text = true, timeout = 30000, stdin = vim.json.encode(body) }):wait()`.

## Tests After Migration

```sh
rg 'plenary\.' lua plugin ftplugin spec test
```

Then run busted (`nlua`/`nvim -l`) or `nix flake check`. Also run a startup
smoke test with minimal runtimepath to catch stale manager dependencies.
