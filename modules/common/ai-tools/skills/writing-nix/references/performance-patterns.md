# Performance-Aware Patterns

Authoring choices that keep evaluation cheap. These are about which construct to
reach for while writing; for profiling and before/after measurement use the
`nix-toolkit` `eval-performance` playbook.

## Folds And Recursion

Prefer the strict `builtins.foldl'` / `lib.foldl'` over `foldl` or hand-written
recursion for list reductions. The prime (`'`) version forces the accumulator at
each step, so it does not build a deep chain of lazy thunks that pressures the
GC and can overflow the evaluation stack.

```nix
# BAD: lazy accumulator, thunk buildup
foldl (acc: x: acc + x) 0 bigList

# GOOD: strict accumulator
builtins.foldl' (acc: x: acc + x) 0 bigList
```

Decision rule:

1. Reducing a list to a value? Use `builtins.foldl'` / `lib.foldl'`.
2. Merging many attrsets? Folding `//` or `recursiveUpdate` over a list
   re-copies the whole accumulator on every step (`O(N^2)`), since attrsets are
   immutable. Use `lib.attrsets.mergeAttrsList` (balanced binary merge) for
   dynamic or large lists; a fixed `a // b // c` chain is fine for a handful.
   See `module-style.md` and the `nix-toolkit` `eval-performance`
   merge-complexity table for detail.
3. Resolving a transitive closure (dependency graphs, reachability)? Use
   `builtins.genericClosure` instead of manual recursion. It is a C++ primop
   that bypasses the Nix recursion limit and dedups in place.

## Local Paths In Strings

Interpolating a local path into a string coerces it by **copying the target into
the Nix store first**. `"${./.}"` at a repo root copies the entire tree on every
eval.

```nix
# BAD: copies the whole directory to the store to resolve the string
configText = "${./.}/config";

# GOOD: keep it a path, or filter precisely with fileset
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
3. Never interpolate a broad directory (`./.`, a monorepo root) into a string.

## String Manipulation

Nix is not built for heavy string work; repeated split/concat over large strings
degrades toward `O(N^2)`.

Decision rule:

1. Do not write parsers in Nix. Read structured data with `builtins.fromJSON` /
   `fromTOML`, or do the parsing in a build step.
2. If a small amount of parsing is unavoidable, tokenize with `builtins.match`
   (C++ regex) and reduce the result with a strict `foldl'`.
3. Avoid building strings just to compare them — see the attribute-path note
   below.

## Attribute Names Over Built Strings

Prefer `hasAttrByPath` / `attrByPath` / `getAttrFromPath` over concatenating
strings and comparing them. Static attribute names are interned and compare by
pointer; dynamically built strings fall back to character-by-character
comparison.

## Module Imports Are Evaluations

Importing a module evaluates it; NixOS eval time scales linearly with the number
of imported modules.

Decision rule:

1. Do not blindly import whole directories or scan large trees with
   `builtins.readDir` at import time. Materialize or narrow the file list.
2. Gate optional modules behind enable options rather than importing everything
   and toggling with `mkIf`, when the import itself is expensive.
3. Keep transient or test configurations to the minimum baseline imports.
