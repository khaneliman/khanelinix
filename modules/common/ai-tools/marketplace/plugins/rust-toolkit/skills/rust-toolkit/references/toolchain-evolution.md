# Rust Toolchain Evolution

Use this mode for edition or MSRV migrations, compiler/Cargo upgrades, target
support changes, and unstable experiments. Long-lived guidance must describe
verification surfaces, not freeze today's release table.

## Intake

Record before proposing change:

- current edition, `rust-version`, toolchain channel/date, and installed targets
- workspace members that intentionally differ in edition or MSRV
- CI, release, deployment, and downstream-consumer toolchains
- exact feature gate, `-Z` flag, RFC, tracking issue, or release claim involved
- stable fallback and exit condition for any experiment

Read the repository's manifests, `rust-toolchain*`, `.cargo/config*`, lockfile,
CI, and release packaging before consulting current official documentation.

## Classify Evidence

| Evidence                                  | Treat as                                                |
| ----------------------------------------- | ------------------------------------------------------- |
| Stable docs matching repository MSRV      | Available, subject to target and edition constraints    |
| Stable docs newer than repository MSRV    | Requires approved MSRV change or compatible alternative |
| `-Z`, `#![feature]`, or nightly docs      | Unstable experiment                                     |
| RFC, project goal, or open tracking issue | Design/status lead, not usable API proof                |
| Accepted syntax on one nightly            | Toolchain-local behavior, not stability                 |
| Third-party benchmark or percentage claim | Hypothesis requiring repository workload measurement    |

Confirm status in the matching channel's Rust Reference, standard-library docs,
Cargo Book, rustc book, release notes, and linked tracking issue. An RFC number
or research report never proves stabilization.

## Edition and MSRV Migration

1. Separate edition changes from compiler-version and dependency upgrades where
   repository policy permits.
2. Run repository checks before migration; preserve a comparable baseline.
3. Use `cargo fix --edition` as a syntax migration aid, then review every diff.
4. Inspect return-position `impl Trait` capture, temporary drop scopes, macro
   fragment behavior, unsafe attributes and extern blocks, static mutation, and
   never-type fallback where relevant to the edition jump.
5. Validate public API, feature combinations, proc macros, generated code, FFI,
   doctests, and supported targets on both minimum and primary toolchains.
6. Migrate workspace members independently when consumers or MSRV policy differ;
   editions interoperate and do not require a big-bang workspace change.

Start from the matching
[Rust Edition Guide](https://doc.rust-lang.org/edition-guide/) and stable
[release notes](https://doc.rust-lang.org/stable/releases.html).

## Nightly Experiment Contract

Before introducing an unstable language, library, Cargo, or codegen feature:

1. State the measured problem and why stable alternatives are insufficient.
2. Pin an exact nightly or otherwise make compiler drift explicit.
3. Isolate enablement behind a narrow package, target, feature, profile, or CI
   lane; do not make unrelated development depend on it.
4. Record the feature gate, current official docs, tracking issue, supported
   targets, and known limitations.
5. Keep a stable implementation or build path unless the user accepts nightly as
   a project requirement.
6. Compare correctness, diagnostics, compile time, runtime, binary size,
   tooling, and target coverage with the stable path.
7. Define removal, stabilization, and rollback criteria.

Use the current
[Rust Unstable Book](https://doc.rust-lang.org/nightly/unstable-book/) and
[Cargo unstable-feature index](https://doc.rust-lang.org/cargo/reference/unstable.html).
Features such as Cargo script mode, profile-selected codegen backends, portable
SIMD, Polonius, return-type notation, unsafe fields, default field values, and
pin projection work must pass this gate whenever official docs still mark them
unstable or experimental.

## Release and Target Changes

- Compare release notes from the pinned compiler through the proposed compiler;
  inspect compatibility notes, future-incompatibility lints, and fixed
  miscompilations, not only headline features.
- Re-check the target-support tier, host tools, standard-library availability,
  linker defaults, minimum OS/runtime requirements, and CI coverage for every
  shipped target.
- Treat symbol mangling, linker strictness, unwinding, debug info, and
  WebAssembly import/export behavior as packaging and observability contracts.
- Update the validation matrix before deleting compatibility code or adopting a
  newly stable API.

Use the current
[platform support matrix](https://doc.rust-lang.org/rustc/platform-support.html)
instead of copying target tiers into the skill.

## Output

Report current state, desired state, evidence URL and date, compatibility
impact, stable fallback, validation matrix, and rollback trigger. Label
proposals and nightly-only syntax explicitly.
