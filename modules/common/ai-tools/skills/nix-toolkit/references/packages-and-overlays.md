# Packages and Overlays

Package, overlay, and flake output conventions for Nix expressions, custom
derivations, and repository package sets.

## Overlays: `final: prev:`

An overlay is a function taking two package set layers and returning an
attribute set of new or modified packages:

```nix
final: prev: {
  hello = prev.hello.overrideAttrs (oldAttrs: {
    patches = (oldAttrs.patches or [ ]) ++ [ ./fix.patch ];
  });
  my-tool = final.callPackage ./my-tool.nix { };
}
```

### Argument Roles and the Open Fixpoint

Nixpkgs names the arguments `final` and `prev`. Older code used `self` and
`super`, but `final: prev:` explicitly clarifies their evaluation stage:

- `prev` is the package set from the preceding layer in the overlay stack.
- `final` is the completed package set after all overlays are applied.

Decision rule:

1. **Use `prev` when modifying an existing package.** Deriving a package from
   `prev.<name>` (for example, `prev.hello.overrideAttrs ...`) modifies the
   existing definition. Calling `final.hello.overrideAttrs ...` inside the
   definition of `hello` causes Nix to recurse infinitely when resolving
   `hello`, failing with `infinite recursion encountered`.
2. **Use `final` for dependencies and `callPackage`.** When adding a new package
   or providing inputs to `final.callPackage`, resolve dependencies from
   `final`. This ensures downstream overrides and packages added by other
   overlays are visible to the new package.
3. **Use `prev` when an override must break a cycle.** If an overlay's modified
   package would trigger a loop when consumed by another tool in the overlay,
   pull the unaffected upstream tool explicitly from `prev`.

### Composition and Ordering

Overlays compose sequentially from left to right:

```nix
{
  pkgs = import nixpkgs {
    overlays = [
      overlayA
      overlayB
    ];
  };
}
```

In `overlayB`, `prev` contains all definitions and overrides made by `overlayA`.
However, `final` in both `overlayA` and `overlayB` points to the identical,
fully composed package set.

### Overlays Versus Call-Site Overrides

| Scope  | Mechanism                                       | Impact                                                                                                                               |
| ------ | ----------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------ |
| Global | Overlay (`final: prev:`)                        | Replaces the package across the entire package set. All downstream packages and modules referencing `pkgs.foo` receive the override. |
| Local  | Call-site (`pkg.override`, `pkg.overrideAttrs`) | Produces an isolated package instance. Other packages in `pkgs` continue referencing the original, unmodified derivation.            |

A single overlay does not force re-evaluation of all of Nixpkgs. Because of lazy
evaluation, only overridden attributes and derivations that transitively depend
on them re-evaluate. However, overriding a foundational package (such as `glibc`
or `openssl`) triggers mass recompilation across dependent packages.

## Overriding Layers

Package customization operates at distinct evaluation seams. Choose the layer
that matches what needs to change.

| Method               | Target Layer                           | Modifies                                      | Fixpoint and Hooks            |
| -------------------- | -------------------------------------- | --------------------------------------------- | ----------------------------- |
| `override`           | Function arguments (`callPackage`)     | Build flags, feature flags, dependency inputs | Re-evaluates package function |
| `overrideAttrs`      | Derivation attributes (`mkDerivation`) | `src`, `patches`, `nativeBuildInputs`, phases | Re-evaluates `mkDerivation`   |
| `overrideDerivation` | Low-level derivation primop            | Raw derivation environment variables          | Bypasses stdenv logic; avoid  |

### Choosing the Override Seam

1. **Use `override` for function arguments.** When a package exposes flags or
   inputs in its top-level function signature (such as `enableFeature ? true` or
   `openssl ? pkgs.openssl`), call `pkg.override { enableFeature = false; }`.
   This re-executes the package expression so internal conditional flags and
   dependencies stay consistent.
2. **Use `overrideAttrs` for derivation inputs and phases.** When you need to
   patch source code, append `cmakeFlags`, or customize `postInstall`, use
   `overrideAttrs`. Modern nixpkgs supports both `oldAttrs: { ... }` and
   `(finalAttrs: previousAttrs: { ... })`.
3. **Never use `overrideDerivation`.** It is a legacy primitive that directly
   mutates derivation attributes after evaluation, bypassing `stdenv` setup
   hooks, losing `passthru`, and risking silent build breakages.
4. **Use package-specific override surfaces.** Ecosystem builders provide
   tailored override methods:
   - Python: `pkg.overridePythonAttrs (old: { ... })`
   - Go: `pkg.overrideAttrs (old: { vendorHash = "..."; })`
   - Rust: `pkg.overrideAttrs (old: { cargoHash = "..."; })`
   - Custom wrappers: packages with `override`, `wrapEnv`, or `withPlugins`

Prefer the dedicated seam over modifying raw derivation attributes when one
exists.

## Derivation Self-Reference with `finalAttrs`

When authoring derivations with `stdenv.mkDerivation`, pass a function taking
`finalAttrs` rather than using `rec`:

```nix
{
  lib,
  stdenv,
  fetchFromGitHub,
  testers,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "my-tool";
  version = "1.2.0";

  src = fetchFromGitHub {
    owner = "example";
    repo = "my-tool";
    rev = "v${finalAttrs.version}";
    hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  };

  passthru.tests = {
    version = testers.testVersion {
      package = finalAttrs.finalPackage;
    };
  };

  meta = {
    description = "Example CLI tool";
    homepage = "https://example.com/my-tool";
    changelog = "https://example.com/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.mit;
    mainProgram = "my-tool";
  };
})
```

### Why `finalAttrs` Replaces `rec`

In derivations authored with `rec { ... }`, self-references bind lexically when
the attrset is defined. If a consumer overrides the derivation using
`pkg.overrideAttrs (old: { version = "2.0.0"; })`, the updated `version` does
not propagate into `src` because `src` closed over the lexical binding. The
build attempts to fetch the old version with the new package name.

With `stdenv.mkDerivation (finalAttrs: { ... })`:

- `finalAttrs` resolves dynamically against the final attributes after all
  `overrideAttrs` calls run. Overriding `version` automatically updates
  `finalAttrs.version` inside `src` and `meta.changelog`.
- `finalAttrs.finalPackage` references the final resulting derivation itself,
  allowing self-referential `passthru.tests` without cyclic evaluation.
- For attribute sets outside derivations, see
  [Anti-patterns](anti-patterns.md#rec) for `rec` versus `let` rules.

## Derivation Essentials

Avoid common derivation authoring mistakes:

### `pname` and `version`

Always declare `pname` and `version` as separate attributes. Never define an
interpolated `name = "${pname}-${version}"`. `stdenv.mkDerivation` automatically
synthesizes `name` from `pname` and `version`. Downstream tools (such as
`nix-update`, Repology, and version checkers) rely on independent `pname` and
`version` fields to parse package metadata.

### Dependency Classification and Closures

Assign dependencies to the input list matching their execution context:

| List                    | Host Architecture | Executed At    | Closure Impact                                   |
| ----------------------- | ----------------- | -------------- | ------------------------------------------------ |
| `nativeBuildInputs`     | `buildPlatform`   | Build time     | Excluded from runtime closure unless referenced  |
| `buildInputs`           | `hostPlatform`    | Target runtime | Retained in runtime closure if referenced        |
| `propagatedBuildInputs` | `hostPlatform`    | Target runtime | Propagated into all downstream consumer closures |

Decision rule:

1. **Put build-time tools in `nativeBuildInputs`.** Compilers, code generators,
   linters, `cmake`, and `pkg-config` execute during the build and belong in
   `nativeBuildInputs`.
2. **Put linked libraries in `buildInputs`.** Shared and static libraries needed
   at runtime by the compiled output belong in `buildInputs`.
3. **Restrict `propagatedBuildInputs` to consumer requirements.** Use propagated
   inputs only when consumers cannot compile or link without them (for example,
   Python package dependencies or C libraries whose public headers include third
   party headers). Propagating normal build tools or internal dependencies
   bloats downstream runtime closures; see
   [Closure analysis](closure-analysis.md).

### Binary Resolution with `lib.getExe`

Never hardcode path strings like `"${pkg}/bin/my-tool"`. Upstream name changes
or path variations break string interpolations silently until runtime.

- Use `lib.getExe pkg` to resolve a package's primary binary. It reads
  `meta.mainProgram`, falling back to `pname`.
- Use `lib.getExe' pkg "auxiliary"` to resolve an alternate binary from a
  multi-binary package.
- Always set `meta.mainProgram` in the `meta` block when the executable name
  differs from `pname`, or when the package produces multiple binaries. This
  ensures `lib.getExe` and `nix run` invoke the expected binary.

### Automation with `passthru.updateScript`

Expose automated upgrade instructions under `passthru.updateScript`:

```nix
{
  passthru.updateScript = nix-update-script { };
}
```

Attributes in `passthru` do not affect the derivation hash and are evaluated
only when explicitly queried by update tools.

## Fixed-Output Hashes

A fixed-output derivation permits network access during the build phase by
requiring the cryptographic hash of the output to be declared in advance. Source
fetchers (`fetchurl`, `fetchFromGitHub`) and ecosystem fetchers (`vendorHash`,
`cargoHash`) all produce one.

### Deriving Hashes with `lib.fakeHash`

1. Set the hash attribute to `lib.fakeHash`:
   ```nix
   {
     src = fetchurl {
       url = "https://example.com/archive-v${finalAttrs.version}.tar.gz";
       hash = lib.fakeHash;
     };
   }
   ```
2. Trigger the build to observe the failure:
   ```bash
   nix build .#my-tool
   # error: hash mismatch in fixed-output derivation '<store-path>':
   #   specified: sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=
   #   got:    sha256-1b4z...
   ```
3. Extract the `got:` SRI hash from the
   `hash mismatch in fixed-output derivation` error message.
4. Replace `lib.fakeHash` with the reported `got:` hash in the derivation.
5. Never leave `lib.fakeHash` in committed code; see
   [Build debugging](build-debugging.md).

## Flake Outputs

Flake outputs organize build artifacts, modules, and utilities across systems.

### Standard Output Schema

| Output                      | Type        | Role                                              |
| --------------------------- | ----------- | ------------------------------------------------- |
| `packages.<system>.<name>`  | Derivation  | Flat package set for the specified system.        |
| `legacyPackages.<system>`   | Attrset     | Lazy package set; allows nested hierarchies.      |
| `apps.<system>.<name>`      | App attrset | Executable programs runnable with `nix run`.      |
| `devShells.<system>.<name>` | Derivation  | Development environments for `nix develop`.       |
| `checks.<system>.<name>`    | Derivation  | CI tests executed by `nix flake check`.           |
| `formatter.<system>`        | Package     | Tree formatter executed by `nix fmt`.             |
| `overlays.<name>`           | Function    | Overlays (`final: prev:`) exported for consumers. |
| `nixosModules.<name>`       | Module      | NixOS configuration modules.                      |
| `darwinModules.<name>`      | Module      | nix-darwin configuration modules.                 |
| `homeModules.<name>`        | Module      | Home Manager configuration modules.               |

### The `forAllSystems` Pattern

Generate per-system outputs by iterating over a system list with `genAttrs`:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.callPackage ./package.nix { };
        }
      );
    };
}
```

### `legacyPackages` Versus `packages`

`packages.<system>` is intended strictly for a flat attribute set of
derivations. Commands such as `nix flake show` and `nix flake check` evaluate
every derivation listed in `packages`.

`legacyPackages.<system>` allows nested attribute sets and lazy evaluation. Nix
evaluates attributes in `legacyPackages` only when explicitly queried.

Never expose an entire Nixpkgs package set (`import nixpkgs { ... }`) under
`packages.<system>`. Doing so causes `nix flake show` to attempt evaluating all
packages in Nixpkgs, exhausting available memory. Expose large or nested package
hierarchies under `legacyPackages.<system>`.

### Keeping `nixpkgs.lib` Out of Per-System Loops

`nixpkgs.lib` is pure Nix and independent of architecture or system. Avoid
instantiating a per-system package set just to access `lib`:

```nix
{ nixpkgs, system }:
{
  # Inefficient: imports nixpkgs per system to obtain lib
  legacyLib = (import nixpkgs { inherit system; }).lib;

  # Preferred: access lib directly from the flake input
  directLib = nixpkgs.lib;
}
```

Instantiating `import nixpkgs { inherit system; }` constructs an entire package
set scope with default overlays and configuration. Accessing
`inputs.nixpkgs.lib` directly at the flake level eliminates this evaluation
overhead; see [Performance patterns](performance-patterns.md) and
[Evaluation performance](eval-performance.md).

## Verify

Run the narrowest check that validates the package, overlay, or output:

1. **Verify overlay evaluation:**
   ```bash
   nix eval --raw .#packages.x86_64-linux.my-tool.version
   ```
2. **Build package output:**
   ```bash
   nix build .#my-tool
   ```
3. **Execute package binary:**
   ```bash
   nix run .#my-tool -- --help
   ```
4. **Validate flake output schema:**
   ```bash
   nix flake show
   ```
5. **Inspect runtime closure:**
   ```bash
   nix path-info -Sh .#my-tool
   ```
