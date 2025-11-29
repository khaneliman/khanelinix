---
name: typescript-validation
description: "Fast TypeScript/JavaScript syntax and type validation. Use when checking .ts/.tsx/.js files, fixing type errors, or before commits."
---

# TypeScript Validation

## Quick Checks

```bash
# Type check only (no emit)
tsc --noEmit

# Check specific file
tsc --noEmit src/file.ts

# With project config
npx tsc --noEmit -p tsconfig.json
```

## Linting

```bash
# ESLint
eslint src/
eslint --max-warnings 0 src/

# Fix auto-fixable
eslint --fix src/
```

## Format Check

```bash
# Prettier check
prettier --check "src/**/*.{ts,tsx}"

# Format files
prettier --write "src/**/*.{ts,tsx}"
```

## Git-Aware

```bash
# Check staged files
git diff --cached --name-only | grep -E '\.(ts|tsx)$' | xargs -r npx tsc --noEmit

# Lint staged
git diff --cached --name-only | grep -E '\.(ts|tsx)$' | xargs -r eslint
```

## Common Errors

| Error                        | Fix                                       |
| ---------------------------- | ----------------------------------------- |
| "Cannot find module"         | Check imports, install deps               |
| "Type X not assignable to Y" | Fix type mismatch or add assertion        |
| "Property does not exist"    | Add to interface or use optional chaining |
| "implicitly has any type"    | Add explicit type annotation              |

## Pre-Commit

```bash
tsc --noEmit && eslint src/ && prettier --check src/
```
