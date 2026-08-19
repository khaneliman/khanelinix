# Rust Toolkit Scripts

Use helpers for bounded inventory and conventional Cargo checks. Read project
instructions first; repository-native commands win when they differ.

## Project Context

Run:

```bash
<skill-dir>/scripts/project-context.py [path] [--json]
```

The script:

- locates the nearest `Cargo.toml`
- reads manifests without changing source or creating a lockfile
- uses locked `cargo metadata --no-deps` only when `Cargo.lock` exists
- reports workspace members, package targets, edition/MSRV, features, dependency
  counts, profiles, toolchain versions, and relevant config files
- falls back to static manifest expansion when Cargo metadata is unavailable

Output is evidence for routing, not an architectural verdict. Read manifests and
call sites before changing boundaries.

## Conventional Quality Gates

Inspect commands without execution:

```bash
<skill-dir>/scripts/rust-verify.sh --dry-run --mode test
```

Run compatible checks:

```bash
<skill-dir>/scripts/rust-verify.sh \
  --manifest-path ./Cargo.toml \
  --mode quick
```

Modes:

- `quick`: `cargo fmt --check`, then workspace/package
  `cargo check --all-targets`
- `test`: quick checks plus `cargo test --all-targets`
- `full`: test checks plus Clippy and rustdoc tests

Optional selectors: `--package`, `--features`, `--all-features`,
`--no-default-features`, `--target`, and `--allow-lockfile-update`.

The helper does not add `-D warnings`, install tools, choose a linker, enable
all features by default, or substitute nextest. It writes only normal Cargo
build artifacts by default; `cargo fmt` runs in check mode and Cargo receives
`--locked`. Projects that intentionally do not track `Cargo.lock` must opt into
lockfile creation with `--allow-lockfile-update` and review the resulting file.

## Selection Rules

- Use focused package/features first during implementation.
- Use workspace and supported feature-matrix checks before delivery.
- Do not combine `--all-features` with mutually exclusive features.
- Pass `--allow-lockfile-update` only when a deliberate lockfile update is in
  scope.
- Use the repository's nextest, cross, cargo-make, just, Nix, or CI wrapper when
  that is the declared validation contract.
