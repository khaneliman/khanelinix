# Lua 5.1 through 5.5 Migration

Use for migration planning, incompatibility diagnosis, and idiomatic
replacements. For execution and acceptance checks, read
[lua-compatibility-verification.md](lua-compatibility-verification.md). Primary
sources checked on 2026-10-11; recheck tool and release support when using this
guidance later.

## Establish the runtime contract

Identify PUC Lua (the reference implementation), LuaJIT, or an embedding host
such as Neovim. Record interpreter paths, exact releases, enabled libraries,
numeric configuration, native modules, and required supported versions. Decide
whether the result is **5.5-only** or **one source tree supporting older
versions too**. Do not drop an existing target implicitly.

Lua's 5.x versions are not interchangeable minor updates: C modules and hosts
must be rebuilt across version boundaries, and precompiled chunks are not
portable between them. As of the research date, the latest reference release is
5.5.1. Neovim's supported language remains Lua 5.1; a system `lua` upgrade does
not change it. [Lua version policy](https://www.lua.org/versions.html),
[Neovim compatibility](https://neovim.io/doc/user/lua/#lua-compat).

Read every intervening incompatibility section, even for a direct 5.1-to-5.5
migration. Intermediate interpreters are useful for locating the first failing
boundary; installing every intermediate release is not required to deploy 5.5.

## Boundary map

| Boundary                                                   | Main audit targets                                                                | Idiomatic direction                                                                                                   |
| ---------------------------------------------------------- | --------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------- |
| [5.1 to 5.2](https://www.lua.org/manual/5.2/manual.html#8) | Environments, legacy modules, renamed library APIs, process status                | Returned module tables, lexical dependencies, explicit `load` environment, `table.unpack`, `package.searchers`        |
| [5.2 to 5.3](https://www.lua.org/manual/5.3/manual.html#8) | Integer/float behavior, bit widths, removed math helpers, table metamethods       | Choose numeric semantics explicitly; format external numbers; preserve 32-bit contracts when replacing `bit32`        |
| [5.3 to 5.4](https://www.lua.org/manual/5.4/manual.html#8) | Comparisons, coercion, RNG, finalization, iterator return counts, GC              | Explicit `__le`, validated numeric inputs, deterministic resource cleanup, deliberate RNG contract                    |
| [5.4 to 5.5](https://www.lua.org/manual/5.5/manual.html#8) | Reserved `global`, read-only loop control variables, nil errors, GC tuning, C API | Rename identifiers, use body-local working variables, meaningful error objects, named GC parameters, rebuilt bindings |

The following is a focused audit, not a substitute for the manuals. Host
extensions, debug hooks, weak tables, and custom allocators need the relevant
manual sections when the program uses them.

## 5.1 to 5.2: modules, environments, and library APIs

- Replace `module(..., package.seeall)` with a local table returned by the file.
  Keep dependencies local with `local dependency = require("dependency")`. This
  avoids implicitly exporting globals and is usable on all targets.
- `getfenv`/`setfenv` are removed. In 5.2+, globals resolve through lexical
  `_ENV`; use `load(source, chunkname, "t", env)` for source that needs an
  explicit environment. This is not a mechanical `setfenv` rename: inspect
  shared closures, thread environments, and sandbox assumptions. `_ENV` has no
  special environment meaning in 5.1.
- Replace `loadstring` with `load` for 5.2+ and use text-only mode when loading
  untrusted source. An environment table alone is not a secure sandbox. Do not
  load untrusted bytecode or treat a `string.dump` closure as a main chunk whose
  first upvalue is necessarily `_ENV`.
- Global `unpack` moves to `table.unpack`; `package.loaders` becomes
  `package.searchers`. `table.maxn` is deprecated: use a sequence length only
  for a real sequence, an explicit count for nil-bearing arguments, or an
  intentional maximum-index scan for sparse numeric tables.
- `os.execute` changes from a numeric status to success/failure plus exit/signal
  information. In 5.1 both zero (success) and nonzero failure statuses are
  truthy; do not use result truthiness across versions. Normalize the contract
  at the existing process boundary and test both success and failure.
- Review older deprecated features, including `table.foreach`/`table.foreachi`
  and `string.gfind`, rather than assuming a 5.1 compatibility build represents
  the default later runtime. Use ordinary iteration and `string.gmatch`.

Sources: [5.2 incompatibilities](https://www.lua.org/manual/5.2/manual.html#8),
[5.1 deprecated features](https://www.lua.org/manual/5.1/manual.html#7.2),
[5.5 `load` contract](https://www.lua.org/manual/5.5/manual.html#pdf-load).

### Small compatibility adapters

Use local aliases for API relocation, not global monkey patches. The following
example was executed on PUC Lua 5.1, 5.2, 5.3, 5.4, 5.5, and LuaJIT 2.1:

```lua
local unpack_values = table.unpack or unpack
local function pack_values(...)
  return { n = select("#", ...), ... }
end

local args = pack_values("first", nil, "third", nil)
assert(args.n == 4)
assert(select("#", unpack_values(args, 1, args.n)) == 4)
```

For 5.5-only code use `table.pack` and `table.unpack` directly. Always retain
`n` when nil arguments matter; neither `#args` nor `ipairs` preserves that
contract. Do not add a general compatibility dependency for a few aliases. If
the program truly needs cross-version environment manipulation or C bindings,
evaluate an established compatibility library and verify its target support
instead of inventing a partial emulation.
[Packing](https://www.lua.org/manual/5.5/manual.html#pdf-table.pack),
[unpacking](https://www.lua.org/manual/5.5/manual.html#pdf-table.unpack).

## 5.2 to 5.3: choose numeric and bitwise semantics

- Numbers gain integer and float subtypes. Integer overflow wraps; `/` is still
  floating-point division, while `//` is floor division. Test large values,
  negative division/modulo, integer conversion, and serialized output. Use
  floats where fractional or floating semantics are intended, not as a blanket
  fix that discards exact integers.
- Default Lua integers are 64-bit, but builds can use other numeric settings.
  Audit `bit32` and LuaJIT `bit` replacements for width, signedness, shifts,
  rotations, and overflow. Native operators are not a drop-in 32-bit substitute.
  Preserve the domain's width at the owning operation.
- Numeric `tostring` output can change, including a `.0` suffix. Use explicit
  `string.format` formats for stable external representations and test the
  project's serializer. Do not alter golden output merely to make tests pass.
- Replace `math.pow(x, y)` with `x ^ y`, `math.atan2(y, x)` with
  `math.atan(y, x)` for 5.3+, and `math.log10(x)` with `math.log(x, 10)` for
  5.2+. Audit removed hyperbolic and exponent-decomposition helpers separately;
  naive formulas may lose the original numerical accuracy.
- Table-library operations now honor indexing/assignment metamethods. `__ipairs`
  is deprecated; modern `ipairs` uses indexing and stops at the first nil. Test
  proxy tables and sparse structures instead of assuming raw access.

Sources: [5.3 incompatibilities](https://www.lua.org/manual/5.3/manual.html#8),
[5.5 numeric types](https://www.lua.org/manual/5.5/manual.html#2.1),
[arithmetic](https://www.lua.org/manual/5.5/manual.html#3.4.1),
[bitwise operations](https://www.lua.org/manual/5.5/manual.html#3.4.2),
[LuaJIT extensions](https://luajit.org/extensions.html).

Native `//`, bitwise operators, `<const>`, `<close>`, and 5.5 declarations
cannot be hidden from an older parser by an `if` branch. For shared source, keep
the oldest target's syntax or load separate runtime-specific modules. Do not
generate code strings merely to evade that constraint.

## 5.3 to 5.4: behavior and resource ownership

- Define `__le` explicitly when `<=` is part of a type's contract; the fallback
  from `__lt` is removed. Test comparison laws appropriate to that type rather
  than adding an incorrect generic negation for a partial ordering.
- Convert and validate numeric strings at input boundaries with `tonumber`. Core
  coercion was removed, but the standard string library still provides
  arithmetic coercion through metamethods. Thus `"1" + "2"` can still work, now
  yielding an integer; it is not evidence of a preserved numeric contract.
- Overflowing decimal integer literals become floats instead of wrapping.
  Integer `for` loops no longer wrap at the limit; zero steps are errors.
- `math.random` changes algorithm and initial seeding. Seed tests explicitly,
  but do not expect the same random sequence across versions even with the same
  seed. If a stored protocol or replay requires an exact stream, preserve an
  explicitly specified generator.
- Overriding global `tostring` no longer changes `print`; use `__tostring` or
  format application output explicitly. UTF-8 decoding rejects surrogates by
  default; preserve the application's encoding policy.
- `io.lines` returns four values, including a closing value. Avoid accidental
  multi-result forwarding, as in `load(io.lines(path, "L"))`; parentheses
  restrict it to one result, but a manually consumed iterator still needs
  deliberate file ownership and closing on failure.
- 5.4 introduces `<close>`, `__close`, and `coroutine.close`. Use explicit
  resource lifetime where the target permits it. Audit normal return, early
  `break`, exceptions, and abandoned coroutines; garbage collection is not
  deterministic cleanup. Finalizer errors produce warnings rather than
  propagating, and callable non-function `__gc` values are now invoked.
- GC modes and tuning change. Preserve measured application requirements; do not
  delete tuning that enforces memory or latency constraints.

Sources: [5.4 incompatibilities](https://www.lua.org/manual/5.4/manual.html#8),
[to-be-closed variables](https://www.lua.org/manual/5.4/manual.html#3.3.8),
[coroutine closing](https://www.lua.org/manual/5.4/manual.html#pdf-coroutine.close),
[5.4 loop rules](https://www.lua.org/manual/5.4/manual.html#3.3.5).

## 5.4 to 5.5: parser breaks and GC parameter changes

- `global` is reserved when `LUA_COMPAT_GLOBAL` is disabled. Rename locals,
  parameters, and bare field names such as `object.global`. A public string key
  need not change: use `object["global"]`. Search results require inspection
  because strings and comments are not identifiers.
- Numeric `for` control variables and the **first** variable of a generic `for`
  loop are read-only. Other generic-loop variables remain assignable. Move
  working-value changes into a body-local binding; if code needs to change the
  actual iteration progression, use an explicit `while` or iterator.
- `error(nil)` no longer yields nil as the caught error object. Give errors
  useful values and test `pcall`/`xpcall` contracts instead of nil sentinels.
- Chained `__call` metamethod resolution is limited to 15 objects. Inspect
  callable proxies if the program builds deep chains.
- `collectgarbage("incremental", ...)` and `("generational", ...)` select modes
  but no longer set tuning parameters. Use
  `collectgarbage("param", name, value)` for tuning. Re-evaluate parameter
  meanings and units; do not simply copy positional numbers into new names. In
  particular, 5.5's positive `"step"` argument accounts for bytes, versus
  kilobytes in 5.4.

Sources: [5.5 incompatibilities](https://www.lua.org/manual/5.5/manual.html#8),
[loop rules](https://www.lua.org/manual/5.5/manual.html#3.3.5),
[5.5 GC interface](https://www.lua.org/manual/5.5/manual.html#pdf-collectgarbage),
[5.4 GC interface](https://www.lua.org/manual/5.4/manual.html#pdf-collectgarbage).

Executed on all six runtime families listed above:

```lua
local values = {}
for index = 1, 3 do
  local adjusted = index + 1
  values[index] = adjusted
end
assert(values[1] == 2 and values[3] == 4)
```

### Optional 5.5 idioms, not migration prerequisites

Existing chunks do not suddenly require declarations for every global. 5.5
starts them with an implicit `global *`; an explicit global declaration changes
which undeclared names are permitted in its scope. Prefer local dependencies and
returned modules first. Use strict declarations only for a 5.5-only project that
benefits from the additional compiler checks. They are syntactic checks, not a
security boundary. A global declaration with an initializer raises an error if
that global already has a non-nil value; do not add it indiscriminately to
reloadable modules.

Named vararg tables (`function f(... args)`) offer an `n` count and indexed
access. Preserve `n` for nil-bearing inputs and use the ordinary `...`/packing
idiom when retaining older targets. Adopting these features is separate from
making a program compatible.
[Declarations](https://www.lua.org/manual/5.5/manual.html#3.3.7),
[named varargs](https://www.lua.org/manual/5.5/manual.html#3.4.11).

## C extensions and embedding hosts

Rebuild the host and every native dependency against each target's headers and
library; a Lua source pass cannot verify their ABI. Use the official signatures,
not casts that conceal an API mismatch. For multiple supported versions, keep
necessary `LUA_VERSION_NUM` branches at the binding boundary.

| Boundary                                                     | Binding audit                                                                                                                                                                                                                                                                                                                                                                              |
| ------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| [5.1 to 5.2](https://www.lua.org/manual/5.2/manual.html#8.3) | Remove environment/global pseudoindices and C environments; use registry globals and shared upvalues. Replace `luaL_register` with module construction plus `luaL_setfuncs`/`luaL_newlib`, `lua_objlen` with `lua_rawlen`, and comparisons with `lua_compare`. Update `lua_load` and `lua_resume` arguments. Allocators must distinguish new blocks using `ptr == NULL`, not `osize == 0`. |
| [5.2 to 5.3](https://www.lua.org/manual/5.3/manual.html#8.3) | Adapt continuation callbacks after `lua_getctx` removal; add `lua_dump`'s `strip` argument; replace deprecated integer-conversion helpers with checked `lua_Integer` handling. Test narrowing and range limits.                                                                                                                                                                            |
| [5.3 to 5.4](https://www.lua.org/manual/5.4/manual.html#8.3) | Update `lua_resume`'s output result count, `lua_version`'s value return, and indexed userdata values. Understand to-be-closed stack slots and finalizer warnings. Old single-user-value APIs remain compatibility macros.                                                                                                                                                                  |
| [5.4 to 5.5](https://www.lua.org/manual/5.5/manual.html#8.3) | Supply `lua_newstate`'s string-hash seed; replace deprecated `lua_resetthread` with `lua_closethread` and remove `lua_setcstacklimit`. Calls requesting results are limited to 250; use `LUA_MULTRET` plus deliberate stack adjustment if more are needed. Migrate GC tuning to `LUA_GCPARAM`.                                                                                             |

For 5.5, `lua_dump` writers must tolerate a final `NULL` buffer of size zero and
must not depend on the older unspecified stack arrangement. `lua_pushvfstring`
returns `NULL` and pushes an error message instead of raising an error; audit
callers that assumed a successful string. These are relevant even when the C
source still compiles.
[Writer contract](https://www.lua.org/manual/5.5/manual.html#lua_Writer),
[dump stack contract](https://www.lua.org/manual/5.5/manual.html#lua_dump),
[formatting errors](https://www.lua.org/manual/5.5/manual.html#lua_pushvfstring).

## Execute the migration

Establish green baseline behavior, inspect dependencies, then make the smallest
changes at the owning module or binding. Fix parser and removed-API failures
before investigating changed semantics. Run the relevant regressions on the
original and target runtimes after each coherent change. Keep older-version
adapters only where support still requires them; do not enable compatibility
switches permanently to hide unresolved failures.

Finish with strict 5.5 compilation, runtime and host integration tests, and a
clean target-specific dependency build. Report supported versions and remaining
coverage gaps. A parser pass, formatter pass, rockspec version range, or one
successful startup is not a program-compatibility claim.
