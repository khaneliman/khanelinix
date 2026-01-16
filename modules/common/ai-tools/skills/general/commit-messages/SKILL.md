---
name: commit-messages
description: Generate conventional commit messages based on staged changes. Use when writing commit messages, understanding conventional commit format, or ensuring consistent commit history.
---

# Commit Message Guide

Generates conventional commit messages that are clear, consistent, and
informative.

## Core Principles

1. **Conventional format** - Follow conventional commits specification
2. **Imperative mood** - "add feature" not "added feature"
3. **Explain why** - Body explains motivation, not just what changed
4. **Concise subject** - 72 characters or less, no period
5. **Scope when helpful** - Include scope when it clarifies the change

## Commit Message Format

```
<type>(<scope>): <subject>

[optional body - explain WHY not WHAT]

[optional footer - BREAKING CHANGE:, Fixes #123]
```

## Commit Types

| Type       | When to Use                 | Example                           |
| ---------- | --------------------------- | --------------------------------- |
| `feat`     | New feature or capability   | `feat(auth): add OAuth2 login`    |
| `fix`      | Bug fix                     | `fix(api): handle null response`  |
| `docs`     | Documentation only          | `docs: update API reference`      |
| `style`    | Formatting, no code change  | `style: fix indentation`          |
| `refactor` | Code change, no new feature | `refactor(utils): simplify logic` |
| `perf`     | Performance improvement     | `perf(db): add query index`       |
| `test`     | Adding or fixing tests      | `test(auth): add login tests`     |
| `build`    | Build system, dependencies  | `build: upgrade webpack to v5`    |
| `ci`       | CI configuration            | `ci: add deploy workflow`         |
| `chore`    | Maintenance tasks           | `chore: update gitignore`         |
| `revert`   | Reverting previous commit   | `revert: undo auth changes`       |

## Determining Scope

Derive scope from the area of code changed:

```
src/auth/login.ts     → auth
src/api/users.ts      → api or users
modules/home/git/     → git
lib/utils/format.ts   → utils
```

**Omit scope when:**

- Changes span multiple unrelated areas
- The type alone is sufficient (e.g., `docs`, `ci`)
- The scope would be too generic (e.g., `code`)

## Breaking Changes

Flag breaking changes with `!` after type:

```
feat(api)!: change response format

BREAKING CHANGE: Response now returns { data, meta }
instead of raw data array.
```

**What counts as breaking:**

- API response/request format changes
- Removed or renamed exports
- Changed function signatures
- Database schema changes
- Configuration format changes

## Good vs Bad Examples

### Good Examples

```
feat(auth): add password reset flow

Implements forgot password with email verification.
Users can now reset passwords without admin help.

Closes #42
```

```
fix(checkout): prevent duplicate order submission

Add debounce to submit button and server-side
idempotency check to prevent charging twice.

Fixes #128
```

```
refactor(utils): extract date formatting to shared module

Consolidates 5 duplicate date formatting implementations
into single source of truth. No behavior change.
```

### Bad Examples

```
# Too vague
fix: fixed bug

# Not imperative
feat: added new feature

# Too long, has period
fix(authentication-service): this fixes the bug where users cannot login.

# Describes WHAT not WHY
refactor: changed function name from foo to bar

# Multiple unrelated changes
fix: fix login and add new feature and update docs
```

## Analyzing Changes for Commit Type

### Step-by-step Process

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

3. **Consider the impact**
   - User-facing change = `feat` or `fix`
   - Developer-facing = `refactor`, `test`, `build`
   - Mixed = usually `feat` or `fix`

## Issue References

```
feat(auth): add SSO support

Implements SAML-based single sign-on for enterprise customers.

Closes #42    # Automatically closes issue
Fixes #38     # Also closes issue
Refs #100     # Links without closing
```

## Multi-line Body Guidelines

Use body when:

- Change is complex and needs explanation
- There's important context about WHY
- Breaking changes need migration info

Keep body:

- Wrapped at 72 characters
- Focused on motivation and context
- Free of redundant information from diff

## See Also

- **Code review**: See [code-review](../code-review/) for reviewing commits
- **Git workflows**: See [git-workflows](../git-workflows/) for branching
  strategies
