# Plenary Migration

Use this when removing `plenary.nvim` from Neovim plugins. Goal: native APIs
first, focused dependencies only when native APIs would make code fragile.

## Migration Rules

- Do not add new `plenary.nvim` usage. Upstream is no longer actively maintained
  and only critical fixes should be expected.
- Set plugin minimum Neovim version to the first version that provides required
  native APIs. For most migrations, target Neovim 0.10+ for `vim.system`.
- Remove plenary from install docs, lazy.nvim specs, rockspec dependencies, Nix
  plugin deps, and CI setup after last `require("plenary.*")` is gone.
- Prefer native `vim.*` APIs over compatibility wrappers. Add small local helper
  functions only when they hide repeated error handling, not to recreate
  Plenary's object model.
- Schedule UI mutations from async callbacks before touching buffers, windows,
  extmarks, or notifications:

```lua
-- template only
vim.system({ "rg", "--files" }, { text = true }, function(result)
  vim.schedule(function()
    if result.code ~= 0 then
      vim.notify(result.stderr, vim.log.levels.ERROR)
      return
    end
    require("my_plugin.results").show(vim.split(result.stdout, "\n", { trimempty = true }))
  end)
end)
```

## Replacement Map

| Plenary module                             | Replacement                                                                                     | Notes                                                                                                                      |
| ------------------------------------------ | ----------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------- |
| `plenary.job`                              | `vim.system()`                                                                                  | Use async callback or `:wait()`. Use `{ text = true }` for normalized text output and `{ timeout = ms }` for bounded jobs. |
| `plenary.path`                             | `vim.fs.joinpath()`, `vim.fs.abspath()`, `vim.fs.basename()`, `vim.fs.dirname()`, `vim.fs.rm()` | Keep paths as strings. Avoid `Path:new()`-style objects.                                                                   |
| `plenary.scandir`                          | `vim.fs.dir()`, `vim.fs.find()`                                                                 | Prefer lazy iterators and targeted search. Use `vim.uv.fs_scandir` only for custom async traversal.                        |
| `plenary.async`                            | native callbacks, small vendored coroutine helper, `nvim-nio`, or `coop.nvim`                   | Pick by complexity. Do not replace one broad dependency with another unless structural concurrency is central.             |
| `plenary.curl`                             | `vim.system({ "curl", ... })`                                                                   | Best for simple HTTP and streaming responses. Use focused HTTP client only for complex sessions.                           |
| `plenary.test_harness`, `plenary.busted`   | `busted` with `nlua` or `nvim -l`; `mini.test` for isolated child-process tests                 | Keep tests close to standard Lua tooling. See testing reference for `neorocksTest`.                                        |
| `plenary.popup`, `plenary.window`          | `vim.api.nvim_open_win()` or `nui.nvim`                                                         | Native float for simple UI; `nui.nvim` for layouts, prompts, trees, and complex widgets.                                   |
| `plenary.strings`                          | `vim.str_byteindex()`, `vim.str_utfindex()`, `vim.fn.strdisplaywidth()`, local pure Lua helpers | Use core UTF helpers for byte/character offsets.                                                                           |
| `plenary.filetype`                         | `vim.filetype`                                                                                  | Use native filetype detection and registration.                                                                            |
| `plenary.log`                              | `vim.notify()` for user-facing messages; minimal local logger for file logs                     | Keep file logging opt-in and cheap. Avoid logging on hot paths.                                                            |
| `plenary.context_manager`, `plenary.class` | plain Lua functions/metatables                                                                  | Prefer direct control flow and simple tables.                                                                              |

## `plenary.job` To `vim.system`

Synchronous command:

```lua
-- before: template only
local Job = require("plenary.job")
local lines = Job:new({
  command = "git",
  args = { "rev-parse", "--show-toplevel" },
}):sync()
```

```lua
-- after: template only
local result = vim.system(
  { "git", "rev-parse", "--show-toplevel" },
  { text = true, timeout = 5000 }
):wait()

if result.code ~= 0 then
  return nil, result.stderr
end

local root = vim.trim(result.stdout)
```

Streaming output:

```lua
-- template only
vim.system({ "curl", "-N", url }, {
  stdout = function(_, data)
    if data then
      vim.schedule(function()
        require("my_plugin.stream").append(data)
      end)
    end
  end,
  stderr = function(_, data)
    if data then
      vim.schedule(function()
        require("my_plugin.log").debug(data)
      end)
    end
  end,
  text = true,
}, function(result)
  vim.schedule(function()
    require("my_plugin.stream").finish(result.code)
  end)
end)
```

Use `vim.uv.spawn()` only when `vim.system()` cannot express required handle,
stdio, or lifecycle behavior. Most plugins should not need raw libuv process
management.

## `plenary.path` And `plenary.scandir`

Keep path operations string-based:

```lua
-- template only
local cache_file = vim.fs.joinpath(vim.fn.stdpath("cache"), "my_plugin", "state.json")
local dir = vim.fs.dirname(cache_file)
vim.fn.mkdir(dir, "p")
```

Use lazy directory iteration when scanning broad trees:

```lua
-- template only
for name, type_ in vim.fs.dir(root, { depth = 2 }) do
  if type_ == "file" and name:sub(-4) == ".lua" then
    table.insert(files, vim.fs.joinpath(root, name))
  end
end
```

Use `vim.fs.find()` for targeted discovery:

```lua
-- template only
local markers = vim.fs.find({ ".git", "stylua.toml", ".luarc.json" }, {
  upward = true,
  path = start_path,
  stop = vim.env.HOME,
})
```

For recursive scans over large repos, avoid building one huge table before work
starts. Process iterator entries incrementally or use `vim.uv.fs_scandir` with a
bounded scheduler.

## `plenary.async`

Choose smallest model that fits behavior:

- Simple subprocess or file operation: use `vim.system()` callbacks or direct
  `vim.uv` callbacks.
- Two or three repeated coroutine waits: vendor a tiny local helper and test it.
- Complex cancellation, semaphores, queues, async LSP, or test runner internals:
  use `nvim-nio`.
- Functional structured concurrency preference: evaluate `coop.nvim`.

Do not introduce `nvim-nio` for one job callback or one filesystem scan. Extra
dependency becomes new required runtime surface.

## `plenary.curl`

For JSON request/response:

```lua
-- template only
local body = vim.json.encode({ prompt = prompt })
local result = vim.system({
  "curl",
  "--silent",
  "--show-error",
  "--fail-with-body",
  "--request",
  "POST",
  "--header",
  "content-type: application/json",
  "--data-binary",
  "@-",
  endpoint,
}, { text = true, timeout = 30000, stdin = body }):wait()

if result.code ~= 0 then
  return nil, result.stderr
end

return vim.json.decode(result.stdout)
```

For token streaming, bind `stdout` callback and parse chunks incrementally. Use
a focused HTTP library only when plugin owns reusable HTTP concerns: cookies,
connection reuse, multipart forms, auth refresh, proxy policy, or retry policy.

## Tests After Migration

After removing Plenary, tests should fail if any module still requires it:

```sh
rg 'plenary\\.' lua plugin ftplugin spec test
```

Then run normal test path from this skill:

- `busted` through `nlua` or `nvim -l` for non-Nix projects.
- `nix build .#checks.<system>.nvim-stable-tests` or `nix flake check` when
  using `neorocksTest`.

Also run a startup smoke test with minimal runtimepath so a stale plugin manager
dependency does not hide missing modules.
