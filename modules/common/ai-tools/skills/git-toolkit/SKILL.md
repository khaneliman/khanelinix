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
- Never emit literal `\n` escape sequences in commit message text.
  - Forbidden: `git commit -m "line1\nline2"`
  - Correct pattern for multi-line bodies: repeat `-m` flags or use a heredoc/file input.

  ```bash
  # preferred
  git commit -m "feat(scope): subject" -m "first body paragraph" -m "second paragraph"
  ```

Commit strategy (must enforce):

- Before committing, follow local history strategy first:
  - prefer `git commit --amend` for immediate HEAD corrections,
  - prefer `fixup` + `--autosquash` for nearby regressions when history is local-only (unshared/unpushed).
  - avoid adding tiny follow-up commits when a history edit is the better option.
- If a change requires splitting, squashing, or reordering, state the target history
  shape before running the command.

## 2a) Hunk-Level Git Strategy

Use `git-surgeon` for non-interactive, hunk-level git operations:

- staging/unstaging/discarding specific hunks
- fixing, amending, or squashing around selected hunks
- undoing or splitting commits by hunk IDs
- reordering commits without broad interactive workflows

Before using it, read [references/git-surgeon.md](references/git-surgeon.md) and follow its safety rules.

## 3) GitHub Extensions

Use [`github-toolkit`](../github-toolkit/) for:

- GitHub PR review comment triage
- Failing PR check triage
- GitHub issue creation

This keeps Git logic and GitHub workflow logic separate.

## Cross-Mode Notes

- For commands that touch shared history or remote state, call out destructive
  risk explicitly before running them.
- If a recent commit introduced a breaking regression and the commit is local-only,
  prefer `fixup` + `--autosquash` (via an interactive rebase) to fold the
  correction into the originating commit, instead of stacking follow-up commits.
- If the commit has been pushed/shared, avoid history rewrite; use conventional
  follow-up commits and/or coordinated PR update flow.
- For multi-step changes, default to minimal safe steps and stop at user
  confirmation points.
- Cross-skill references are intentionally non-duplicative: only `git` materials stay
  in this toolkit.
