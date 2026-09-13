# Performance-Aware Patterns

Candidate authoring patterns, not measured speedups. Use
[Review scenarios](review-scenarios.md) for change thresholds and semantic
checks. These are about which construct to reach for while writing; for
profiling and before/after measurement use the
[Evaluation performance](eval-performance.md) playbook.

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
independent of `config` and `_module.args`; see the
[Nixpkgs module API](https://nixos.org/manual/nixpkgs/stable/#module-system-lib-evalModules).

Decision rule:

1. Profile import discovery and repeated Nixpkgs evaluation before reducing
   imports. Cost depends on forced work, not merely the number of files.
2. Keep static module imports and gate their definitions with `mkIf`. Select
   optional imports only from import-time inputs such as `specialArgs` when
   appropriate; verify that required options remain declared.
3. Narrow expensive `builtins.readDir` discovery only after checking coverage.
   Keep transient test configurations to the required baseline imports.
