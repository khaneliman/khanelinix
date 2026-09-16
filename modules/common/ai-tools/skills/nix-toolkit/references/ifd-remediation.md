# IFD Remediation

## 1. Lexical Sinks (Triggers)

These functions trigger IFD when their argument is a derivation object or store
path requiring realization:

| function                         | note |
| :------------------------------- | :--- |
| `import expr`                    |      |
| `builtins.readFile expr`         |      |
| `builtins.readDir expr`          |      |
| `builtins.pathExists expr`       |      |
| `builtins.filterSource f expr`   |      |
| `builtins.path { path = expr; }` |      |
| `builtins.hashFile t expr`       |      |
| `builtins.scopedImport x drv`    |      |

Static local paths (e.g. `builtins.readFile ./config.json`) do NOT trigger IFD.

## 2. Detection

```bash
nix build .#package --option allow-import-from-derivation false
nix eval .#package --option allow-import-from-derivation false
nix flake check --option allow-import-from-derivation false
```

`allow-import-from-derivation` is a boolean setting, so Nix generates
`--allow-import-from-derivation` and `--no-allow-import-from-derivation`,
neither of which takes an argument. Writing
`--allow-import-from-derivation false` leaves `false` to be parsed as an
installable and fails with a selection-path error. Use the `--option` form
above, or `--no-allow-import-from-derivation`.

### Error Signatures

```text
error: cannot build '/nix/store/...-source.drv' during evaluation because the option 'allow-import-from-derivation' is disabled
```

Cross-compilation may also show host/target mismatch:

```text
error: a 'aarch64-darwin' with features {} is required to build '/nix/store/...', but I am a 'x86_64-linux' with features {}
```

### Tracing Obscured IFD

1. Inject `builtins.trace` around suspected sinks; stall after a print →
   subsequent expression is the IFD.
2. Interactive debugger:
   ```bash
   nix build .#package --show-trace --debugger --print-build-logs --verbose
   ```
3. Static analysis: scan AST for filesystem sinks (`readFile`, `import`)
   referencing variable targets.

## 3. Remediation Protocols

### Alpha: Explicit Parameterization (Rust/Crane)

Crane reads `Cargo.toml` from remote source to discover `pname`/`version` →
triggers IFD.

```nix
# Anti-pattern
my-crate = craneLib.buildPackage { src = inputs.remote-src; strictDeps = true; }

# Fix: explicit params bypass dynamic file inspection
my-crate = craneLib.buildPackage {
  pname = "my-rust-app";
  version = "0.1.0";
  src = inputs.remote-src;
  strictDeps = true;
}
```

### Beta: De-shelling / Native Nix Sinks

```nix
# Anti-pattern: runCommand with gcc/sed/jq, then import result
stripComments = path: pkgs.runCommand "strip-comments" {} ''
  ${lib.meta.getExe' pkgs.gcc "cpp"} -P -E "${path}" > "$out"
'';
settings = builtins.fromJSON (builtins.readFile (stripComments ./settings.json));

# Fix: process natively in Nix
settings = builtins.fromJSON (builtins.readFile ./settings.json);
```

Replace shell preprocessing with `builtins.split`, `builtins.replaceStrings`,
`builtins.fromJSON`, or stdlib string helpers.

### Gamma: Materialization (Haskell/haskell.nix/cabal2nix)

Generate and commit dynamic files locally; eval reads static files.

```bash
#!/usr/bin/env bash
# update-nix-from-cabal.sh
set -euo pipefail
for cabal_file in */*.cabal; do
  dir=$(dirname "$cabal_file")
  cabal2nix "$dir" > "$dir/default.nix"
done
```

```nix
# Import materialized output instead of callCabal2nix
haskell-pkg = pkgs.haskellPackages.callPackage ./src/default.nix {};
```

### Delta: Pre-fetching External Dependencies

Decouple network calls from evaluation: lock revisions and hashes beforehand via
`flake.lock`, `niv`, or `npins`.

## 4. Parallel Evaluation (Determinate Nix)

When IFD is architecturally unavoidable, parallel evaluation can hide some of
its cost. This is Determinate Nix only; upstream Nix evaluates single-threaded.

Parallel evaluation shipped in Determinate Nix 3.11.1 behind `eval-cores`, which
defaulted to 1 and needed `eval-cores = 0` to use every core. Since 3.16.3 it
defaults to unlimited cores, so no opt-in is required on a current release. Set
it only to cap parallelism.

Determinate Nix owns `/etc/nix/nix.conf`. Put overrides in
`/etc/nix/nix.custom.conf`, or in `nix.settings` on a NixOS host, so a daemon
upgrade does not discard them.

`builtins.parallel` parallelizes evaluation inside an expression and is gated
behind a separate experimental feature:

```text
extra-experimental-features = parallel-eval
```

```nix
builtins.parallel [
  (import ./arch-x86.nix)
  (import ./arch-aarch64.nix)
]
```

Treat `builtins.parallel` as unstable. Determinate documented it as subject to
significant semantic change or removal during the developer preview, and it is
absent from the 3.22.4 builtins reference. Confirm it exists on the pinned
Determinate version before depending on it; prefer removing the IFD.

## Verification Checklist

- [ ] `--option allow-import-from-derivation false` eval succeeds.
- [ ] Eval time measured with `eval-benchmark.sh` (before/after).
- [ ] No external builder steps during evaluation phase.
