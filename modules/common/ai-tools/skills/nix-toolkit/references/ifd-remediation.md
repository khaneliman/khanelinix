# Import From Derivation (IFD) Remediation

Use this playbook to detect, diagnose, and refactor Import From Derivation (IFD)
bottlenecks in Nix evaluations.

---

## 1. Mechanics and Lexical Sinks

Import From Derivation occurs when the Nix evaluator requires the output of an
unrealized derivation to complete the instantiation of the dependency graph.
This forces a synchronous, single-threaded build during the evaluation phase,
leading to "head-of-line blocking."

### Lexical Triggers (Sinks)

When the argument passed to any of the following functions is a **derivation
object** or a **store path requiring realization**, it triggers an IFD block:

| built-in function                | Operational Purpose                                                      |
| :------------------------------- | :----------------------------------------------------------------------- |
| `import expr`                    | Parses and evaluates a Nix expression from the resulting file.           |
| `builtins.readFile expr`         | Ingests the contents of a file and returns it as a Nix string.           |
| `builtins.readDir expr`          | Returns an attribute set mapping filenames to file types in a directory. |
| `builtins.pathExists expr`       | Returns a boolean indicating if a specific path exists.                  |
| `builtins.filterSource f expr`   | Filters a source tree based on a user-defined predicate function.        |
| `builtins.path { path = expr; }` | Adds a path to the Nix store and returns its formalized store path.      |
| `builtins.hashFile t expr`       | Computes the cryptographic hash of a file.                               |
| `builtins.scopedImport x drv`    | Imports a Nix expression while overriding the default lexical scope.     |

> [!NOTE]
> Utilizing these functions on static local repository paths (e.g.
> `builtins.readFile ./config.json`) does **not** trigger IFD. The file must
> originate from a derivation output (e.g. `pkgs.runCommand` or a fetched remote
> source).

---

## 2. Detection and Diagnostics

### Enforcing Strict Hermetic Evaluation

To detect IFD or prevent it entirely, set the `allow-import-from-derivation`
option to `false`. When disabled, Nix throws a fatal error immediately upon
encountering an IFD.

Run the following commands to check for IFD:

```bash
# Enforce strict evaluation dynamically on CLI
nix build .#package --option allow-import-from-derivation false
nix eval .#package --allow-import-from-derivation false
nix flake check --allow-import-from-derivation false
```

### Error Signatures

If an IFD is triggered under strict evaluation, you will encounter the following
output:

```text
error: cannot build '/nix/store/...-source.drv' during evaluation because the option 'allow-import-from-derivation' is disabled
```

For cross-compilation contexts, this may also manifest as host/target
mismatches:

```text
error: a 'aarch64-darwin' with features {} is required to build '/nix/store/...', but I am a 'x86_64-linux' with features {}
```

### Diagnostic Tracing

When the source of an IFD is obscured by layers of abstractions:

1. **Step-by-Step Print Tracing**: Inject `builtins.trace` around suspected
   sinks. If evaluation stalls after a specific print, the subsequent expression
   contains the IFD.
2. **Detailed Stack Trace & Debugger**: Run the evaluation with the interactive
   debugger:
   ```bash
   nix build .#package --show-trace --debugger --print-build-logs --verbose
   ```
3. **Static Analysis**: Scan the abstract syntax tree for occurrences of
   filesystem sinks (`readFile`, `import`) referencing variable targets that
   resolve to derivations.

---

## 3. Refactoring and Remediation Protocols

### Protocol Alpha: Explicit Parameterization (Rust / Crane)

**Context**: Crane attempts to automatically discover `pname` and `version` by
reading `Cargo.toml` of a source tree. If the source tree is a remote input
(e.g. from a flake input), reading it triggers an IFD block.

**Remediation**: Explicitly provide static attributes to bypass dynamic file
inspection.

```nix
# Anti-pattern: Reading Cargo.toml from remote source triggers IFD
my-crate = craneLib.buildPackage {
  src = inputs.remote-src;
  strictDeps = true;
}

# Remediation: Explicit parameters short-circuit metadata inspection
my-crate = craneLib.buildPackage {
  pname = "my-rust-app";
  version = "0.1.0";
  src = inputs.remote-src;
  strictDeps = true;
}
```

---

### Protocol Beta: De-shelling / Native Nix Sinks

**Context**: Using shell commands inside a utility derivation (e.g. `runCommand`
with `gcc`, `sed`, or `jq`) to preprocess configuration strings, and then
importing them.

**Remediation**: Perform file filtering and string transformations natively in
Nix using built-ins (`builtins.split`, `builtins.replaceStrings`,
`builtins.fromJSON`, or standard library string helpers).

```nix
# Anti-pattern: GCC preprocessor strips comments, triggering IFD
stripComments = path: pkgs.runCommand "strip-comments" {} ''
  ${lib.meta.getExe' pkgs.gcc "cpp"} -P -E "${path}" > "$out"
'';
settings = builtins.fromJSON (builtins.readFile (stripComments ./settings.json));

# Remediation: Perform string cleanup or parsing inside Nix language memory
settings = builtins.fromJSON (
  # Example: strip comments natively or structure config files purely in Nix
  builtins.readFile ./settings.json
);
```

---

### Protocol Gamma: Materialization (Haskell / haskell.nix / cabal2nix)

**Context**: Generating package and dependency graphs dynamically using tools
like `cabal2nix` or `haskell.nix`.

**Remediation**: Capture the dynamically generated files and save them to the
repository (materialization). Evaluations can then read the static files
directly.

1. Create a script to generate and commit the files locally:
   ```bash
   #!/usr/bin/env bash
   # update-nix-from-cabal.sh
   set -euo pipefail

   for cabal_file in */*.cabal; do
     dir=$(dirname "$cabal_file")
     echo "Generating $dir/default.nix from $cabal_file"
     cabal2nix "$dir" > "$dir/default.nix"
   done
   ```
2. Modify the Nix code to import the static file:
   ```nix
   # Import the materialized output instead of callCabal2nix
   haskell-pkg = pkgs.haskellPackages.callPackage ./src/default.nix {};
   ```

---

### Protocol Delta: Pre-fetching External Dependencies

**Context**: Dynamic fetches during evaluation to resolve dependency lists or
lockfiles.

**Remediation**: Decouple network calls from evaluation by locking revisions and
cryptographic hashes beforehand using Flakes (`flake.lock`), `niv`, or `npins`.
Nix can then evaluate against the pre-fetched local metadata instantly.

---

## 4. Evaluator Tuning: Parallel Evaluation

If IFD is architecturally unavoidable (e.g. dynamic multi-architecture matrix
generation), leverage the experimental parallel evaluation capabilities of
Determinate Nix (version 3.11.0+).

### System Configuration

Enable parallel evaluation in `/etc/nix/nix.conf` or user settings:

```text
eval-cores = 0
extra-experimental-features = parallel-eval
```

### Language Optimization

Use the explicit parallel builder construct to instruct the evaluator to
evaluate branches concurrently:

```nix
# Explicitly evaluate heavy IFD expressions concurrently
builtins.parallel [
  (import ./arch-x86.nix)
  (import ./arch-aarch64.nix)
]
```

---

## Verification Checklist

- [ ] Run evaluation with `--option allow-import-from-derivation false` and
      confirm it succeeds.
- [ ] Measure evaluation time using the `eval-benchmark.sh` script to verify the
      speedup.
- [ ] Ensure that no external builder steps or daemon jobs run during evaluation
      (i.e. before the build phase actually begins).
