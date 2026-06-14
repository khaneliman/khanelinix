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
2. **pull-request-creation** — prepare a PR title/body file that matches the
   repository’s required PR template.
3. **issue-triage** — find, filter, and summarize GitHub issues for selection or
   contribution.
4. **pr-review** — collect, prioritize, and address review comments on the PR
   for the current branch.
5. **ci-fix** — inspect failing PR checks and summarize actionable fix context.

If intent is unclear, ask for the mode before acting.

## 1) Issue Creation Mode

Use when the user provides raw notes, logs, dictation, or screenshots and wants
a ready-to-file GitHub issue.

Read [issue-creation.md](references/issue-creation.md). Template usage is
mandatory:

- Discover repository templates before drafting (paths in the reference).
- If an `ISSUE_TEMPLATE` is present, fill the issue strictly from that template.
- Do not skip template structure, sections, or required fields. Match acceptance
  criteria in [acceptance-criteria.md](references/acceptance-criteria.md).

## 2) Pull Request Creation Mode

Use when user asks for PR body drafting, PR summary text, or PR creation
assistance.

Read [pull-request-creation.md](references/pull-request-creation.md). Template
usage is mandatory:

- Discover repository templates before drafting PR body.
- If a `PULL_REQUEST_TEMPLATE` is present, fill it strictly.
- Do not skip required template sections.

## 3) Issue Triage Mode

Use when the user asks to find issues, recommend issues to work on, audit open
issues, compare labels, or inspect issue activity in a GitHub repository.

Read [issue-triage.md](references/issue-triage.md) before running searches. It
contains the current `gh` command patterns, field-name quirks, and reporting
checklist for efficient issue discovery.

## 4) PR Review Mode

Use for review-comment triage or high-signal review of the PR associated with
the current branch.

Read [pr-review.md](references/pr-review.md) for review collection, high-signal
policy, inline comment rules, and no-issues response.

## 5) CI Fix Mode

## Template Compliance (global)

- Treat repository issue and PR templates as hard requirements.
- If a repo exposes template files/directories, use exactly one template branch
  in the generated output.
- If multiple templates exist and intent is unclear, ask user to pick one before
  drafting and only proceed after selection.

Use for failing checks in the PR linked to the current branch (or provided PR).

Read [ci-fix.md](references/ci-fix.md) for PR check discovery, failure summary,
and implementation guardrails.

## Cross-Mode Notes

- Prefer minimal, safe edits first.
- Ask for explicit approval before touching files from issue summaries or CI
  recommendations.
- For destructive git operations (hard reset, force push, branch deletion), call
  out risk before running them.
