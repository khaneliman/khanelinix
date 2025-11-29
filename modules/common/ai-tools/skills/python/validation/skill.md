---
name: python-validation
description: "Fast Python syntax and type validation. Use when checking .py files, fixing type errors, or before commits."
---

# Python Validation

## Quick Checks

```bash
# Syntax check
python -m py_compile file.py

# Check all in directory
python -m py_compile *.py
```

## Type Checking

```bash
# mypy
mypy file.py
mypy src/

# pyright (faster)
pyright file.py
```

## Linting

```bash
# ruff (fast, replaces flake8+isort+more)
ruff check .
ruff check --fix .

# pylint
pylint src/
```

## Format Check

```bash
# black
black --check .
black .  # to format

# ruff format
ruff format --check .
ruff format .
```

## Git-Aware

```bash
# Check staged files
git diff --cached --name-only | grep '\.py$' | xargs -r ruff check

# Type check staged
git diff --cached --name-only | grep '\.py$' | xargs -r mypy
```

## Common Errors

| Error              | Fix                                 |
| ------------------ | ----------------------------------- |
| "SyntaxError"      | Check indentation, colons, brackets |
| "NameError"        | Import missing or typo              |
| "TypeError"        | Wrong argument types                |
| "has no attribute" | Check object type, add Optional     |

## Pre-Commit

```bash
ruff check . && ruff format --check . && mypy .
```
