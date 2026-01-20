---
name: validating-nix
description: Validates Nix code correctness, syntax, and buildability. Use when checking for errors, debugging build failures, formatting code, or verifying flake outputs.
---

# Validating Nix

## Validation Workflow

Copy this checklist when validating changes:

```
Validation Progress:
- [ ] Phase 1: Syntax check passes
- [ ] Phase 2: Formatting is correct
- [ ] Phase 3: Evaluation succeeds
- [ ] Phase 4: Build dry-run succeeds
- [ ] Phase 5: Quality checks pass
- [ ] Phase 6: Project conventions verified
```

Follow this hierarchy of validation:

1. **Syntax**: Basic parse check
2. **Formatting**: Code style
3. **Evaluation**: Expression correctness
4. **Build**: Derivation realization
5. **Quality**: Best practices & linting
6. **Conventions**: Project-specific rules

## Phase 1: Syntax Check

Parse files without evaluating to catch syntax errors.

```bash
# Quick check all modified files
git diff --name-only '*.nix' | xargs nix-instantiate --parse

# Check specific file
nix-instantiate --parse ./path/to/file.nix

# Check all files (via find)
find . -name "*.nix" -exec nix-instantiate --parse {} + >/dev/null
```

**Common errors:**

- Missing semicolons
- Unmatched brackets/braces
- Invalid escape sequences

If syntax check fails, fix errors before proceeding.

## Phase 2: Formatting

Ensure code adheres to project style (using `nixfmt` or `treefmt`).

```bash
# Check formatting (no changes)
nix fmt -- --check

# Fix formatting if needed
nix fmt
```

Only proceed when formatting is clean.

## Phase 3: Evaluation

Check that expressions resolve correctly without actually building.

```bash
# Flake check (no build)
nix flake check --no-build

# If you changed system config
nix eval .#nixosConfigurations.<host>.config.system.build.toplevel --dry-run

# If you changed home config
nix eval .#homeConfigurations.<user>@<host>.activationPackage --dry-run

# Evaluate specific expression
nix eval --file ./default.nix
```

**Common issues:**

- Undefined variables → Check imports and cfg bindings
- Type errors → Verify option types match values
- Infinite recursion → Check for circular dependencies

If evaluation fails, fix before building.

## Phase 4: Build Testing

Verify that derivations can actually be built.

```bash
# Dry run (checks without building)
nix build .#nixosConfigurations.<host>.config.system.build.toplevel --dry-run

# Or for home
nix build .#homeConfigurations.<user>@<host>.activationPackage --dry-run
```

**Only if dry-run succeeds:**

```bash
# Actual build test
nix build .#nixosConfigurations.<host>.config.system.build.toplevel

# Or build specific attribute
nix build .#packages.x86_64-linux.default
```

## Phase 5: Quality Checks

```bash
# Check for anti-patterns (if available)
statix check .
deadnix .
```

### Static Analysis

Use tools like `statix` or `deadnix` to find anti-patterns:

- **`with` usage**: Avoid excessive `with lib;`. Use `inherit (lib) ...`
- **Unused variables**: Remove defined but unused bindings
- **Hardcoded paths**: Use `lib.mkOption` or relative paths

## Phase 6: Project Conventions

Manual review checklist:

- [ ] Variables use camelCase
- [ ] Files use kebab-case
- [ ] Options under `khanelinix.*` namespace
- [ ] No `with lib;` usage
- [ ] Proper `inherit (lib)` usage
- [ ] Module follows standard structure (`imports`, `options`, `config`)

## Quick Troubleshooting

| Error Message                                         | Likely Cause              | Solution                                      |
| ----------------------------------------------------- | ------------------------- | --------------------------------------------- |
| `error: undefined variable 'foo'`                     | Typo or missing import    | Check cfg binding and imports                 |
| `error: infinite recursion`                           | Circular dependency       | Check option references, avoid rec            |
| `error: value is a function while a set was expected` | Missing function argument | Check module arguments ({ config, lib, ... }) |
| `error: attribute 'x' missing`                        | Typo in attribute path    | Verify config path exists                     |
| Format check fails                                    | Code not formatted        | Run `nix fmt`                                 |

## See Also

- **Writing code**: See [writing-nix](../writing-nix/) for best practices and
  anti-patterns
- **Managing flakes**: See [managing-flakes](../managing-flakes/) for debugging
  evaluation errors
