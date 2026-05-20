# Closure Analysis

Use this playbook for package/system size changes, unexpected dependencies, or
cache/substitution questions.

## Scripted Diff

Use the bundled script when comparing two installables or store paths:

```bash
scripts/closure-diff-report.sh nixpkgs#hello nixpkgs#hello
```

It builds without linking, prints direct closure sizes, runs
`nix store diff-closures`, shows raw added/removed store paths, and lists the
largest entries in the resulting closure.

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

For built result symlinks:

```bash
nix path-info -Sh result
nix path-info -rSh result | sort -h
```

## Dependency Drift

```bash
nix path-info -r .#before | sort > before.paths
nix path-info -r .#after | sort > after.paths
diff -u before.paths after.paths
nix store diff-closures .#before .#after
```

Use names and store paths cautiously: path hashes change when inputs change.
Focus on package identity, role, and size impact.

## Interpreting Size Regressions

1. Check whether the direct output grew with `nix path-info -Sh`.
2. If recursive size grew but direct size did not, inspect added closure paths.
3. If a dependency appears only in the derivation graph, treat it as build-time
   until a runtime reference proves otherwise.
4. If a multi-output package is involved, compare the exact output path, not
   only the package name.

## Reverse Dependency Questions

Use `nix why-depends` when the question is why one output depends on another:

```bash
nix why-depends .#package nixpkgs#dependency
nix why-depends --derivation .#package nixpkgs#dependency
nix why-depends --all .#package nixpkgs#dependency
```

Use `--derivation` when runtime references do not explain the dependency; it
shows build-time edges. Use `--all` only after the shortest path is understood.

For deeper unwanted-dependency work, switch to
[dependency-forensics.md](dependency-forensics.md).

## Reference Queries

Use legacy store queries for built outputs when you need exact reference sets:

```bash
nix-store -q --references result | sort
nix-store -q --referrers result | sort
nix-store -q --tree result
```

`--referrers` depends on the local store database; absence of a referrer is not
proof that no external binary cache or other machine refers to the path.

## Advanced Interpretation

- `nix store diff-closures` groups by package name/version, which is better for
  human review than raw store path diffs.
- Raw store path diffs are still useful when generated outputs changed name but
  not version.
- A larger direct output and a larger recursive closure are different bugs.
- Multiple versions of the same library usually point to input graph drift,
  overlays, or mixed `nixpkgs` instances.

## Reporting Checklist

- Total closure size before/after.
- Largest added dependencies.
- Removed dependencies.
- Whether the size change is direct output size or dependency closure.
- Follow-up build or package changes needed.
