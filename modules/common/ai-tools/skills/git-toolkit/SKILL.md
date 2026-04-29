---
name: git-toolkit
description: Git workflows, commit discipline, and safe local history operations.
---

# Git Toolkit

Use this skill for branch strategy, conflict handling, and commit quality.

## How I choose what to do (progressive disclosure)

When invoked, route to one mode:

1. **workflow** — branching strategy, conflict resolution, commit history, and
   basic Git operations.
2. **commit-message** — conventional commit style, scope, and quality checks.
3. **github-toolkit** — any GH PR review comments, check triage, or issue creation.

If intent is unclear, ask for the mode before applying changes.

## 1) Workflow Mode

Use for task planning, branch hygiene, rebase/merge decisions, conflict
resolution, and `git` command guidance.

- Check [git-reference.md](references/git-reference.md) for command/reference tables.
- Check [git-examples.md](references/git-examples.md) for workflow templates.

## 2) Commit Message Mode

Use for commit message policy and drafting, including commit format choice and
scope rules.

- Check [commit-reference.md](references/commit-reference.md) for commit type tables
  and rules.
- Check [commit-examples.md](references/commit-examples.md) for good/bad examples.

Core policy:

- Match the repository history (`git log`) first.
- Prefer imperative, short, scoped subjects.
- Avoid `\n` as a literal escape in normal quoted `git commit -m`.

## 3) GitHub Extensions

Use [`github-toolkit`](../github-toolkit/) for:

- GitHub PR review comment triage
- Failing PR check triage
- GitHub issue creation

This keeps Git logic and GitHub workflow logic separate.

## Cross-Mode Notes

- For commands that touch shared history or remote state, call out destructive
  risk explicitly before running them.
- If a recent commit introduced a breaking regression, prefer `fixup` +
  `--autosquash` to fold the correction into the originating commit, instead of
  stacking tiny follow-up commits.
- For multi-step changes, default to minimal safe steps and stop at user
  confirmation points.
- Cross-skill references are intentionally non-duplicative: only `git` materials stay
  in this toolkit.
