# Performance-Aware Patterns

Choose constructs that match the operation and preserve its semantics. These
patterns guide writing and refactoring Nix; they do not establish speedups. Use
[Evaluation performance](eval-performance.md) for profiling, measurements, and
deciding whether a tradeoff is worthwhile.

## Sharing Work

Keep ordinary bindings at their [narrowest useful scope](bindings.md). For
repeated, item-independent work inside `map (item: ...)`, consider sharing the
result outside the map. For example, `parse sharedText` can be a shared binding
when it does not depend on `item`. Do not hoist item-dependent inputs.

Compare the consumed result and lazy error behavior before timing representative
input sizes. Expanding scope is not automatically faster; use measurements when
cost, rather than readability, is the reason for the transformation.

## Folds And Recursion

Prefer `builtins.foldl'` / `lib.foldl'` for reductions that need a strict
accumulator. Preserve intentional laziness; strict folds do not force every
nested field. The strict (`'`) variant forces the accumulator at each step,
avoiding lazy thunk chains that pressure GC and can overflow the eval stack.

```nix
# Lazy accumulator candidate
foldl (acc: x: acc + x) 0 bigList

# Strict numeric reduction
builtins.foldl' (acc: x: acc + x) 0 bigList
```

Decision rule:

1. Reducing a list with a required accumulator? Prefer `builtins.foldl'` /
   `lib.foldl'`; check intentional lazy behavior before changing existing code.
2. Merging many shallow attrsets? Compare `lib.mergeAttrsList` with a fold of
   `//` when profiling identifies growing-accumulator copying. Preserve
   collision order. It is not a replacement for `recursiveUpdate` or module
   merging. A fixed `a // b // c` chain is fine for a handful. Inspect the
   pinned implementation before claiming complexity; see
   [Evaluation performance](eval-performance.md).
3. Resolving a transitive closure (dependency graphs, reachability)? Use
   `builtins.genericClosure` instead of manual recursion. It is a C++ primop
   that bypasses the Nix recursion limit and dedups in place.

`foldl'` forces intermediate results, not all nested fields; `deepSeq` imposes a
stronger demand. See the
[Nix built-ins reference](https://nix.dev/manual/nix/2.35/language/builtins.html#builtins-foldl').
Compare ordered results, empty inputs, and unused-value errors when changing
strictness. For list-producing operations, prefer `concatMap f xs` over a
growing list accumulator when that expresses the operation directly.

## Attribute-Set Composition

| Need                       | Construct                      | Semantics                                                  |
| -------------------------- | ------------------------------ | ---------------------------------------------------------- |
| Small fixed shallow update | `a // b // c`                  | Rightmost value wins.                                      |
| List of shallow updates    | `lib.mergeAttrsList fragments` | Preserve list order and shallow collisions.                |
| Nested updates             | `lib.recursiveUpdate`          | Merge nested attributes recursively.                       |
| Module definitions         | `lib.mkMerge`                  | Use option types, priorities, and conditional definitions. |
| Values grouped by key      | `lib.zipAttrsWith`             | The supplied function determines the resulting value.      |

A growing-accumulator fold of `//` may repeatedly copy keys. For large inputs,
compare it with `mergeAttrsList`; inspect the pinned implementation before
claiming complexity. See
[Nixpkgs attrset source](https://github.com/NixOS/nixpkgs/blob/master/lib/attrsets.nix).

Include empty input, duplicate keys, and nested collisions in semantic checks.
For `[ { nested.a = 1; } { nested.b = 2; } ]`, shallow merging keeps only
`nested.b`; recursive merging retains both. These are different operations, not
interchangeable optimizations.

## Local Paths In Strings

Interpolating a local path into a string copies the target into the Nix store.
`"${./.}"` at a repo root requests the entire tree when that string is forced.
Existing store contents and evaluator caching affect the actual work.

```nix
# Broad directory coercion
configText = "${./.}/config";

# Path-valued consumer
configPath = ./config;

# Separate derivation-source use case
src = lib.fileset.toSource {
  root = ./.;
  fileset = lib.fileset.unions [ ./config ./lib ];
};
```

Decision rule:

1. Need a path value? Keep it a path (`./config`); do not interpolate it into a
   string just to append to it.
2. Need a derivation source? Use `lib.fileset` to select only the required files
   before they reach the store.
3. Avoid accidental broad-directory coercion; retain intentional store-path
   references and all files required by the consumer.

Path interpolation creates a store reference; retaining a path value does not
perform the same coercion. See
[String interpolation](https://nix.dev/manual/nix/2.35/language/string-interpolation.html).
Inspect selected source files and build the affected derivation when narrowing a
source. Keep required files, intentional string context, and runtime store
references.

## String Manipulation

Repeated split/concat over large strings degrades toward `O(N^2)`.

Decision rule:

1. Do not write parsers in Nix. Read structured data with `builtins.fromJSON` /
   `fromTOML`, or do the parsing in a build step.
2. If a small amount of parsing is unavoidable, tokenize with `builtins.match`
   (C++ regex) and reduce the result with a strict `foldl'`.
3. Avoid building strings just to compare them. See the attribute-path note
   below.

## Attribute Names Over Built Strings

Use `hasAttrByPath` / `attrByPath` / `getAttrFromPath` when the input is a list
of path components. Preserve missing-key and fallback behavior. Do not rewrite
ordinary attribute selection on an unmeasured string-interning hypothesis.

## Module Import Boundaries

Imports must resolve before final configuration. Keep import selection
independent of `config` and `_module.args`; see
[module arguments](module-style.md#module-arguments) for the phase distinction
and the
[Nixpkgs module API](https://nixos.org/manual/nixpkgs/stable/#module-system-lib-evalModules).

Decision rule:

1. Profile import discovery and repeated Nixpkgs evaluation before reducing
   imports. Cost depends on forced work, not merely the number of files.
2. Keep static module imports and gate their definitions with `mkIf`. Select
   optional imports only from import-time inputs such as `specialArgs` when
   appropriate; verify that required options remain declared.
3. Narrow expensive `builtins.readDir` discovery only after checking coverage.
   Keep transient test configurations to the required baseline imports.

Evaluate both feature states and confirm that required option declarations stay
available. Reuse a Nixpkgs package set only when system, overlays, and
configuration match; compare affected package derivation paths.

Primary sources linked here were consulted on 2026-09-13. Nix language links
target 2.35; module manuals and master source can move. Verify the project's
pinned implementation before relying on version-specific behavior.
