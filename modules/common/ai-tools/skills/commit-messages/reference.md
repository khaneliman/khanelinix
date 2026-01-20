# Commit Message Reference

## Commit Types (Conventional)

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

## Alternative Conventions

### Path-Based (Scoped)

Used in some monorepos or specific projects (e.g., Nixpkgs-style).

**Format:** `path/to/component: subject` or `filename: subject`

**Examples:**

- `programs/waybar: update to 0.9.13`
- `modules/nixos/docker: fix socket permissions`
- `init.lua: refactor plugin loading`

**When to use:**

- When the project strictly follows a file-path based convention.
- When working in large monorepos where the path is the most significant
  context.
- **Check `git log` first** to confirm if this is the active convention.
