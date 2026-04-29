---
name: git-toolkit
description: Git and GitHub PR workflows, commit discipline, review-comment handling, and CI failure triage for repository workflows.
---

# Git Toolkit

Use this single skill as the entry point for Git/GitHub work.

## How I choose what to do (progressive disclosure)

When invoked, route to one mode:

1. **workflow** — branching strategy, conflict resolution, commit history, and
   basic Git operations.
2. **commit-message** — conventional commit style, scope, and quality checks.
3. **pr-review** — GitHub PR comment discovery and correction workflow.
4. **ci-fix** — failing GitHub Actions checks and log-driven fix planning.

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

## 3) PR Review Mode

Use for loading and addressing review/issue comments on the current branch PR.

### Workflow

1. Verify GitHub CLI auth: `gh auth status`.
2. Run:

   - `python "<path-to-skill>/scripts/fetch_comments.py"`

3. Summarize actionable comments and ask the user which threads to resolve.
4. Apply only selected changes and report what was updated.

If auth/rate limits fail, ask the user to re-run `gh auth login`.

## 4) CI Fix Mode

Use for failing checks in the current branch PR.

### Workflow

1. Verify `gh auth status`.
2. Resolve PR (`current branch` or user-provided PR number/URL).
3. Fetch and summarize failures:

   - `python "<path-to-skill>/scripts/inspect_pr_checks.py" --repo "." --pr "<num-or-url>"`
   - Add `--json` when automation-friendly output is needed.

4. For each failure, provide the check name, run URL/log context, and a fix plan.
5. Ask for explicit approval before implementation.

If checks are not GitHub Actions, report URL-only and avoid claiming internal
details.

## Cross-Mode Notes

- For commands that touch shared history or remote state, call out destructive
  risk explicitly before running them.
- For multi-step changes, default to minimal safe steps and stop at user
  confirmation points.
- Re-use `git-toolkit` references instead of duplicating logic across skills.

