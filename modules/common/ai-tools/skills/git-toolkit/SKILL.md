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
3. **github-toolkit** — any GH PR review comments, check triage, or issue
   creation.

If intent is unclear, ask for the mode before applying changes.

## 1) Workflow Mode

Use for task planning, branch hygiene, rebase/merge decisions, conflict
resolution, and `git` command guidance.

- Check [git-reference.md](references/git-reference.md) for command/reference
  tables.
- Check [git-examples.md](references/git-examples.md) for workflow templates.

## 2) Commit Message Mode

Use for commit message policy and drafting, including commit format choice and
scope rules.

- Check [commit-reference.md](references/commit-reference.md) for commit type
  tables and rules.
- Check [commit-examples.md](references/commit-examples.md) for good/bad
  examples.
- Check [commit-discipline.md](references/commit-discipline.md) for local
  history strategy, fixup/autosquash, and message CLI safety.

When asked to commit, inspect the full diff and state an atomic commit plan
before creating the first commit. Default to the smallest committable scope, not
one commit per user request or feature name. Split independently buildable
setup, adoption, configuration, generated output, cleanup, formatting, tests,
and documentation even when they all support the same feature.

## 2a) Hunk-Level Git Strategy

Use `git-surgeon` for non-interactive, hunk-level git operations:

- staging/unstaging/discarding specific hunks
- fixing, amending, or squashing around selected hunks
- undoing or splitting commits by hunk IDs
- reordering commits without broad interactive workflows

Before using it, read [references/git-surgeon.md](references/git-surgeon.md) and
follow its safety rules.

## 3) GitHub Extensions

Use [`github-toolkit`](../github-toolkit/) for:

- GitHub PR review comment triage
- Failing PR check triage
- GitHub issue creation

This keeps Git logic and GitHub workflow logic separate.

## Cross-Mode Notes

Read [operating-rules.md](references/operating-rules.md) for shared-history
risk, GitHub boundary, and stop points.
