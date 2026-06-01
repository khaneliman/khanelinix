---
name: github-toolkit
description: GitHub issue triage, issue creation, PR review, and CI check-fix workflows using gh CLI.
---

# GitHub Toolkit

Use this skill for GitHub-specific workflows.

## How I choose what to do (progressive disclosure)

When invoked, choose one mode:

1. **issue-creation** — convert messy inputs into a structured GitHub issue
   markdown file.
2. **issue-triage** — find, filter, and summarize GitHub issues for selection or
   contribution.
3. **pr-review** — collect, prioritize, and address review comments on the PR
   for the current branch.
4. **ci-fix** — inspect failing PR checks and summarize actionable fix context.

If intent is unclear, ask for the mode before acting.

## 1) Issue Creation Mode

Use when the user provides raw notes, logs, dictation, or screenshots and wants
a ready-to-file GitHub issue.

Read [issue-creation.md](references/issue-creation.md) for template and output
rules. Match acceptance criteria in
[acceptance-criteria.md](references/acceptance-criteria.md).

## 2) Issue Triage Mode

Use when the user asks to find issues, recommend issues to work on, audit open
issues, compare labels, or inspect issue activity in a GitHub repository.

Read [issue-triage.md](references/issue-triage.md) before running searches. It
contains the current `gh` command patterns, field-name quirks, and reporting
checklist for efficient issue discovery.

## 3) PR Review Mode

Use for review-comment triage or high-signal review of the PR associated with
the current branch.

Read [pr-review.md](references/pr-review.md) for review collection, high-signal
policy, inline comment rules, and no-issues response.

## 4) CI Fix Mode

Use for failing checks in the PR linked to the current branch (or provided PR).

Read [ci-fix.md](references/ci-fix.md) for PR check discovery, failure summary,
and implementation guardrails.

## Cross-Mode Notes

- Prefer minimal, safe edits first.
- Ask for explicit approval before touching files from issue summaries or CI
  recommendations.
- For destructive git operations (hard reset, force push, branch deletion), call
  out risk before running them.
