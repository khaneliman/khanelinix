# Closure Analysis

## Scripted Diff

```bash
scripts/closure-diff-report.sh nixpkgs#hello nixpkgs#hello
```

Builds without linking, prints direct closure sizes, runs
`nix store diff-closures`, shows added/removed store paths, lists largest
entries.

## Size Summary

```bash
out="$(nix build --no-link --print-out-paths .#package)"

nix path-info -Sh "$out"
nix path-info -rSh "$out" | sort -h
nix path-info --json --json-format 1 --recursive --closure-size "$out" \
  | jq 'to_entries | sort_by(.value.closureSize) | reverse | .[:20][] | {
      path: .key,
      closureSize: .value.closureSize,
      narSize: .value.narSize
    }'
```

For result symlinks:
`nix path-info -Sh result && nix path-info -rSh result | sort -h`

## Dependency Drift

```bash
nix path-info -r .#before | sort > before.paths
nix path-info -r .#after | sort > after.paths
diff -u before.paths after.paths
nix store diff-closures .#before .#after
```

Focus on package identity and size impact; path hashes change when inputs
change.

## Interpreting Size Regressions

1. Direct output grew → `nix path-info -Sh`.
2. Recursive grew but direct did not → inspect added closure paths.
3. Dependency only in derivation graph → treat as build-time until runtime
   reference proves otherwise.
4. Multi-output package → compare the exact output path, not just package name.

## Reverse Dependency

```bash
nix why-depends .#package nixpkgs#dependency
nix why-depends --derivation .#package nixpkgs#dependency  # build-time edges
nix why-depends --all .#package nixpkgs#dependency
```

Use `--derivation` when runtime references don't explain the dependency. Use
`--all` only after shortest path is understood.

For deeper unwanted-dependency work →
[dependency-forensics.md](dependency-forensics.md).

## Reference Queries

```bash
nix-store -q --references result | sort
nix-store -q --referrers result | sort   # local store only; absence ≠ no external referrers
nix-store -q --tree result
```

## Interpretation Notes

- `nix store diff-closures` groups by package name/version — better for human
  review than raw path diffs.
- Raw path diffs catch generated outputs that changed name but not version.
- Direct output size vs recursive closure size are different bugs.
- Multiple versions of same library → input graph drift, overlays, or mixed
  nixpkgs instances.

## Reporting Checklist

- Total closure size before/after.
- Largest added/removed dependencies.
- Whether size change is direct output or dependency closure.
- Follow-up changes needed.
