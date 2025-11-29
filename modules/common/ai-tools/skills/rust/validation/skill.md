---
name: rust-validation
description: "Fast Rust syntax and type validation. Use when checking .rs files, fixing compiler errors, or before commits."
---

# Rust Validation

## Quick Checks

```bash
# Check without building (fast)
cargo check

# Check specific package
cargo check -p package-name

# Check all targets
cargo check --all-targets
```

## Linting

```bash
# Clippy lints
cargo clippy

# Treat warnings as errors
cargo clippy -- -D warnings

# Fix auto-fixable
cargo clippy --fix
```

## Format Check

```bash
# Check formatting
cargo fmt --check

# Format code
cargo fmt
```

## Testing

```bash
# Run tests
cargo test

# Check tests compile (no run)
cargo test --no-run
```

## Common Errors

| Error                      | Fix                                    |
| -------------------------- | -------------------------------------- |
| "cannot borrow as mutable" | Check ownership, use &mut or clone     |
| "value moved here"         | Clone, use reference, or restructure   |
| "mismatched types"         | Check type signatures, add conversions |
| "cannot find"              | Add use statement or check path        |

## Pre-Commit

```bash
cargo fmt --check && cargo clippy -- -D warnings && cargo test
```

## Faster Iteration

```bash
# Use cargo-watch for auto-check
cargo watch -x check

# Quick compile check
cargo check 2>&1 | head -50
```
