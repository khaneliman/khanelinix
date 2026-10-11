# Verify Lua Version Compatibility

Use with [lua-version-migration.md](lua-version-migration.md). The goal is
evidence for a particular program, runtime build, and dependency set, not a
generic certificate that its files are compatible. Tool support was researched
on 2026-10-11; confirm the installed releases before relying on it.

## What each check establishes

| Check                                              | Evidence                                                                      | Not established                                                                                 |
| -------------------------------------------------- | ----------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------- |
| Matching `luac -p`                                 | Selected files compile under that runtime's parser and build options          | Library availability, dynamically generated source, dependencies not selected, runtime behavior |
| LuaLS diagnostics with the intended target         | Static findings and annotated type contracts                                  | Full behavioral or native-module compatibility                                                  |
| Luacheck                                           | Static warnings and configured standard globals within its supported dialects | A complete 5.5 grammar or runtime check                                                         |
| StyLua `--check` / `--verify`                      | Formatting / reparsing and structural verification of formatted output        | Correct application semantics or strict 5.5 compatibility                                       |
| Tests under the target interpreter                 | Behavior of exercised paths with that dependency set                          | Untested paths, other runtime builds, embedding hosts                                           |
| Rebuilt native modules plus host integration tests | Exercised binding and embedding behavior                                      | All platforms or compiler configurations                                                        |

Use the official interpreter and matching compiler as the language authority.
The compiler's `-p` option compiles without executing or writing bytecode.
[Compiler source](https://www.lua.org/source/5.5/luac.c.html),
[interpreter options](https://www.lua.org/manual/5.5/manual.html#7).

## 1. Inventory and establish baseline behavior

- Resolve the real interpreter path and print `_VERSION`; for LuaJIT also record
  `jit.version`. A binary called `lua` or a Busted executable's name does not
  establish which runtime executes the tests.
- Run the existing suite on the current runtime. Record pre-existing failures
  separately from migration regressions.
- Identify entrypoints, modules, generated chunks, rockspecs, configuration
  scripts, native modules, and dynamically loaded dependencies. Include shipped
  files that startup does not happen to require.
- Record `package.path`, `package.cpath`, host-provided APIs, dependency
  versions, and any non-default numeric or compatibility build options.

Command templates below assume Bash and explicit absolute executable paths:

```bash
lua55=/path/to/lua-5.5/bin/lua
luac55=/path/to/lua-5.5/bin/luac
"$lua55" -v
"$luac55" -v
"$lua55" -E -e 'print(_VERSION); print(package.path); print(package.cpath)'
```

`-E` ignores Lua environment variables, including `LUA_INIT` and search-path
overrides. Set intentional project paths in the runner when using it; do not
accidentally remove a required deployment configuration. Test that deployment
configuration separately.
[Lua CLI](https://www.lua.org/manual/5.5/manual.html#7).

## 2. Check a strict 5.5 build, not only a compatibility build

The official 5.5.1 `luaconf.h` defines `LUA_COMPAT_GLOBAL`, allowing `global` as
a name. A runtime reporting 5.5 can therefore mask a reserved-word problem.
Build an additional interpreter/compiler from the verified official source with
compatibility definitions disabled in `luaconf.h`; keep the source and build
under the project's ignored build directory or the user's cache. Follow the
release's build instructions for the platform. A compiler `-U` flag alone does
not defeat a later `#define` in that header.
[Compatibility definition](https://www.lua.org/source/5.5/luaconf.h.html),
[build instructions](https://www.lua.org/manual/5.5/readme.html),
[upstream strict-testing recommendation](https://www.lua.org/manual/5.5/manual.html#8).

Point `lua55` and `luac55` at that strict build for the following checks. This
probe was executed on a compatibility-disabled Lua 5.5.1:

```bash
"$lua55" -E -e '
  assert(not load("local global = 1"))
  assert(not load("for i = 1, 2 do i = i + 1 end"))
  assert(not load("for k, v in pairs({}) do k = 2 end"))
  assert(load("for k, v in pairs({}) do v = 2 end"))
'
```

The last assertion matters: only the first generic-loop variable is read-only.
These probes distinguish relevant build/parser behavior; they do not replace the
program's syntax scan or tests.
[5.5 loop semantics](https://www.lua.org/manual/5.5/manual.html#3.3.5).

## 3. Compile the full selected source inventory

Single-file form, executed with the matching compiler on the migration examples:

```bash
"$luac55" -p -- path/to/module.lua
```

Project scan template, using Bash, ripgrep, and GNU `xargs`; substitute the
project's actual source roots and include generated/dependency roots when
applicable:

```bash
set -o pipefail
rg --files -0 -g '*.lua' -g '*.rockspec' src tests |
  xargs -0 -r -n 1 "$luac55" -p --
```

The NUL-delimited inventory handles spaces; `-n 1` compiles each chunk
separately and avoids combining unrelated files. `pipefail` preserves inventory
failures, including no matching files, rather than reporting an empty scan as
success. Inspect ignored and generated files explicitly: ripgrep's default
exclusions are not a definition of the shipped program. Save or report the
selected roots and count. Compile runtime-generated source with the target's
`load` as part of the tests that construct it; static file scanning cannot cover
it.

For shared source, repeat compilation with each required PUC Lua compiler.
LuaJIT has no matching `luac`; use a trusted-source `loadfile` check in a small
test driver without calling the returned function, then execute its suite under
LuaJIT. Do not use `dofile` as a supposedly side-effect-free syntax check.
[LuaJIT CLI](https://luajit.org/running.html),
[loading versus execution](https://www.lua.org/manual/5.1/manual.html#pdf-loadfile).

## 4. Use static tools within their actual support

- **LuaLS:** 3.16.0 introduced Lua 5.5 support; current configuration source
  includes `"Lua 5.5"` in `runtime.version`. Some published settings docs lag
  behind. Check the installed release, set the real target, and leave
  nonstandard syntax extensions off unless the embedding host requires them. For
  shared code, run diagnostics for the oldest supported target too; one setting
  cannot establish all versions' API availability. Keep LuaCATS checks, but
  remember LuaLS 3.18.1 deliberately accepts `global` as an ordinary name
  outside a declaration, unlike the strict reference parser.
  [Changelog](https://github.com/LuaLS/lua-language-server/blob/master/changelog.md),
  [configuration source](https://github.com/LuaLS/lua-language-server/blob/master/script/config/template.lua),
  [CLI checking](https://luals.github.io/wiki/usage/#check).
- **Luacheck:** the maintained project advertises syntax support for 5.1-5.4 and
  LuaJIT. `--std lua54` selects known standard globals; it does not mean that
  the program was checked against 5.5. `--std max` is a union, not the
  intersection needed for portability. Keep it for supported source, but do not
  invent `lua55` configuration or disable warnings to disguise a migration
  failure. [Project](https://github.com/lunarmodules/luacheck),
  [standards](https://luacheck.readthedocs.io/en/stable/cli.html#command-line-options).
- **StyLua:** its documented dialect list currently reaches `Lua54`, not
  `Lua55`, and default `All` accepts a union of dialects. Configure the intended
  supported syntax, preserve formatting checks, and verify formatter support
  before adopting 5.5-only declarations or named varargs. `--verify` is not a
  runtime-equivalence proof. If the formatter cannot parse required new syntax,
  report the tooling gap rather than rewriting it into a different dialect.
  [Syntax configuration and verification](https://github.com/JohnnyMorganz/StyLua#configuring-runtime-syntax-selection).

For a standalone 5.5 project, the `.luarc.json` target is:

```json
{ "runtime.version": "Lua 5.5" }
```

With a release supporting that target, the standard diagnostics command is a
project template:

```bash
lua-language-server --configpath=.luarc.json --check=. --checklevel=Warning
```

Inspect diagnostics and use the project's CI failure convention; do not infer a
clean result merely from server startup. Supply libraries/types for actual host
APIs rather than declaring undefined names globally to silence them.

The existing [Neovim tooling reference](tooling-and-quality.md) remains the Lua
5.1 plugin path. Do not change its target just because standalone migration work
now uses 5.5.

## 5. Run behavior and dependency tests on the actual target

Use the project's existing runner. A standalone runner invocation is a template,
not a claim that every project uses this file layout:

```bash
"$lua55" -E -W tests/run.lua
```

`-W` enables warnings, including finalizer errors. Warnings alone do not force a
nonzero exit: the runner must assert cleanup/error behavior and make relevant
warnings fail using its own conventions. For Busted, verify that the installed
runner and dependencies actually use 5.5; `nlua` executes through Neovim and
does not validate standalone 5.5.
[Warnings and CLI](https://www.lua.org/manual/5.5/manual.html#7),
[Busted runtime selection](https://lunarmodules.github.io/busted/),
[nlua](https://github.com/mfussenegger/nlua).

Choose regressions from features the program really uses:

- Nil-bearing varargs and multiple returns, including iterator forwarding.
- Large integers, negative division, bit widths, numeric input validation, and
  serialized/printed representations.
- Proxy tables, comparisons, callable chains, and deterministic ordering where
  output needs it. Do not assert `pairs` order, which Lua leaves unspecified.
- Process success/failure, meaningful error objects, and `pcall`/`xpcall` paths.
- File/userdata cleanup on return, error, early break, and coroutine closure.
- Seeded RNG behavior under the intended contract, UTF-8 policy, and existing
  memory/latency requirements under new GC settings.
- Dynamic loading, optional integrations, and every required native module in
  the actual embedding host.

Use fresh version-specific LuaRocks trees or the project's existing isolated
dependency mechanism. Select the target interpreter before resolving/building
rocks; rebuild C modules against its headers and library, and inspect the
resulting search paths. Do not reuse a 5.1/5.4 native module directory for 5.5
or widen `dependencies = { "lua ..." }` in a rockspec before validation. A
version constraint is a resolver declaration, not compatibility evidence.
[LuaRocks CLI target options](https://github.com/luarocks/luarocks/blob/main/src/luarocks/cmd.lua),
[rockspec dependencies](https://github.com/luarocks/luarocks/blob/main/docs/rockspec_format.md),
[Lua ABI policy](https://www.lua.org/versions.html).

## 6. Define the acceptance matrix and report its limits

For **5.5-only**, gate on the actual deployment build plus strict 5.5
compilation and tests, a fresh target dependency build, and host integration
when embedded. For **multi-version support**, run syntax, dependencies, and
behavior on every claimed PUC version from 5.1 through 5.5 and add LuaJIT if
claimed. For **Neovim-only**, retain real Neovim stable/nightly tests; 5.5 tests
of a portable core are additional evidence, not a replacement.

Report exact releases and build options, selected source coverage, commands,
dependency/native-module results, regressions fixed, and unexercised features.
Distinguish "selected files compile", "tested paths work", and "the project
passes its compatibility acceptance matrix". Do not claim universal
compatibility from a narrower result.
