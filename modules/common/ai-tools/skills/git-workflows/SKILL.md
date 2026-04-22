---
name: git-workflows
description: Git version control workflows, branching strategies, and conflict resolution. Use when managing branches, resolving merge conflicts, understanding git history, or following team git conventions.
---

# Git Workflows Guide

Expert guidance for Git version control workflows, branching strategies, and
conflict resolution.

## Core Principles

1. **Atomic commits** - One logical change per commit
2. **Clear history** - Meaningful commit messages that explain why
3. **Branch hygiene** - Keep branches focused and short-lived
4. **Safe operations** - Understand destructive commands before using
5. **Collaboration-friendly** - Follow team conventions consistently

## Detailed Reference Material

- [examples.md](examples.md) - Common workflows, including Feature Branch,
  Trunk-Based, Conflict Resolution, and fixup/autosquash examples.
- [reference.md](reference.md) - Branch naming conventions, conflict strategies,
  command reference tables, and fixup/autosquash strategy.

## Quick Summary

### Branch Naming

Use prefixes like `feat/`, `fix/`, `docs/`, `refactor/` to categorize your
branches.

### Workflow Checklist

**Before starting work:**

- [ ] Pull latest from main
- [ ] Create appropriately named branch
- [ ] Understand the task scope

**During work:**

- [ ] Commit frequently with clear messages
- [ ] Keep changes focused on one concern
- [ ] Rebase on main periodically for long branches

**Before PR:**

- [ ] Rebase on latest main
- [ ] Squash fixup commits
- [ ] Run tests and linting
- [ ] Write clear PR description

### Fixup + Autosquash

Use this when follow-up fixes belong to earlier commits and you want clean,
atomic history:

```bash
git commit --fixup=<target-commit-hash>
GIT_SEQUENCE_EDITOR=: git rebase -i --autosquash <oldest-target-hash>^
```

Then verify with:

```bash
git log --oneline -n 20
git status --short
```

### Multiline Commit Messages

Do not put `\n` inside a normal quoted `git commit -m` string and expect a
newline. Git takes that text literally.

Bad:

```bash
git commit -m "subject" -m "line one\nline two"
```

Prefer one of these patterns instead:

```bash
# Separate paragraphs with multiple -m flags
git commit \
  -m "docs(ai-tools): clarify git commit newlines" \
  -m "Document that normal quoted \n stays literal in git commit bodies.

Prefer -F or multiple -m flags for longer messages."

# Put literal newlines directly in the quoted string
git commit -m "subject" -m "first line
second line

third paragraph"

# In bash/zsh, ANSI-C quoting interprets escapes
git commit -m "subject" -m $'first line\nsecond line\n\nthird paragraph'

# Safest for longer messages
git commit -F- <<'EOF'
docs(ai-tools): clarify git commit newlines

Document that normal quoted \n stays literal in git commit bodies.

Prefer -F or multiple -m flags for longer messages.
EOF
```

Rule of thumb:

- `"\n"` in normal shell quotes is usually literal
- `$'...\n...'` interprets escapes in bash/zsh
- For commit messages, `-F` or multiple `-m` flags are the least error-prone

## Useful Git Commands

### Inspection Commands

```bash
# View commit history
git log --oneline -20
git log --graph --all --oneline

# See what changed
git diff                      # Working vs staged
git diff --cached            # Staged vs last commit
git diff main..feature       # Between branches

# Find who changed what
git blame <file>
git log -p -- <file>         # History of a file
```

### Safety Guidelines

1. **Never force push to main/master**
2. Check if others are using the branch before force pushing
3. Use `--force-with-lease` instead of `--force` when possible
4. Communicate with team first

## See Also

- **Commit messages**: See [commit-messages](../commit-messages/) for
  conventional commit format
- **Code review**: See [code-review](../code-review/) for PR review guidelines
