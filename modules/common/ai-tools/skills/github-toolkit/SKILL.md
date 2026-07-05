---
name: github-toolkit
description: GitHub issue triage, issue creation, PR review, and CI check-fix workflows using gh CLI.
---

# GitHub Toolkit

Use this skill for GitHub-specific workflows.

## How I choose what to do

When invoked, choose one mode:

1. **issue-creation** — convert raw notes/logs/dictation into a structured
   GitHub issue file.
2. **pull-request-creation** — prepare a PR title/body matching the repository's
   PR template.
3. **issue-triage** — find, filter, and summarize GitHub issues for selection or
   contribution.
4. **pr-review** — collect, prioritize, and address review comments on the PR
   for the current branch.
5. **ci-fix** — inspect failing PR checks and summarize actionable fix context.

If intent is unclear, ask for the mode before acting.

## Template Compliance (global)

- Treat repository issue and PR templates as hard requirements.
- If a repo exposes template files/directories, use exactly one template branch
  in the output.
- If multiple templates exist and intent is unclear, ask user to pick one before
  drafting.
- For PR or issue creation, read contribution guidance before drafting:
  `CONTRIBUTING.md`, root/local instruction files, and directly relevant docs.
  Treat required tests, docs, security, and licensing rules as hard constraints.

## 1) Issue Creation Mode

Read [issue-creation.md](references/issue-creation.md). Template usage is
mandatory:

- Discover repo templates before drafting (paths in the reference).
- Read contribution guidance before drafting.
- If an `ISSUE_TEMPLATE` is present, fill strictly from that template.
- Do not skip template structure, sections, or required fields.

## 2) Pull Request Creation Mode

Read [pull-request-creation.md](references/pull-request-creation.md). Template
usage is mandatory:

- Discover repo templates before drafting PR body.
- Read contribution guidance before drafting.
- If a `PULL_REQUEST_TEMPLATE` is present, fill it strictly.
- Do not skip required template sections.

## 3) Issue Triage Mode

Read [issue-triage.md](references/issue-triage.md) before running searches.
Contains `gh` command patterns, field-name quirks, and reporting checklist for
efficient issue discovery.

## 4) PR Review Mode

Read [pr-review.md](references/pr-review.md) for review collection, high-signal
policy, inline comment rules, draft review editing, and no-issues response.

## 5) CI Fix Mode

Read [ci-fix.md](references/ci-fix.md) for PR check discovery, failure summary,
and implementation guardrails.

## Cross-Mode Notes

- Write GitHub-visible text like a helpful teammate: concise, natural, and free
  of repeated details.
- Prefer minimal, safe edits first.
- Ask for explicit approval before touching files from issue summaries or CI
  recommendations.
- For destructive git operations (hard reset, force push, branch deletion), call
  out risk before running.
