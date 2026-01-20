---
name: commit-messages
description: Generate conventional commit messages based on staged changes. Use when writing commit messages, understanding conventional commit format, or ensuring consistent commit history.
---

# Commit Message Guide

Generates conventional commit messages that are clear, consistent, and
informative.

## Core Principles

1. **Follow Project Style** - Mimic existing `git log` patterns above all else.
2. **Imperative mood** - "add feature" not "added feature"
3. **Explain why** - Body explains motivation, not just what changed
4. **Concise subject** - 72 characters or less, no period
5. **Scope when helpful** - Include scope when it clarifies the change

## Commit Formats

### 1. Conventional Commits (Standard)
The most common standard, widely used across the industry.

```
<type>(<scope>): <subject>
```
*Example:* `feat(auth): add login page`

### 2. Path-Based / Scoped (Alternative)
Common in monorepos or systems like Nixpkgs.

```
<path/to/component>: <subject>
```
*Example:* `programs/waybar: update config`

## Detailed Reference Material

- [reference.md](reference.md) - **Commit Types** table, Scope determination, **Breaking Changes**, and **Alternative Conventions**.
- [examples.md](examples.md) - Good and bad examples for various scenarios.

## Analyzing Changes for Commit Type

1. **Look at files changed**
   - New files = likely `feat`
   - Test files only = `test`
   - Config/build files = `build` or `ci`
   - README/docs = `docs`

2. **Examine the diff**
   - Bug fix patterns = `fix`
   - New exports/functions = `feat`
   - Restructuring = `refactor`
   - Optimizations = `perf`

3. **Check `git log`**
   - Verify if the repo uses `type(scope):` or `path/to/file:` style.

## See Also

- **Code review**: See [code-review](../code-review/) for reviewing commits
- **Git workflows**: See [git-workflows](../git-workflows/) for branching strategies
