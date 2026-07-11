---
name: github-toolkit
description: GitHub issue discovery, targeted triage, issue creation, pull-request creation, review authoring, review-feedback handling, and CI check-fix workflows using gh CLI. Use for read or write work against GitHub issues, pull requests, reviews, or checks.
---

# GitHub Toolkit

Route to one mode and load only named reference:

1. **issue-creation** — draft or explicitly create issue. Read
   [issue-creation.md](references/issue-creation.md).
2. **pull-request-creation** — draft or explicitly create pull request. Read
   [pull-request-creation.md](references/pull-request-creation.md).
3. **issue-discovery** — search, filter, rank, or summarize many issues. Read
   [issue-discovery.md](references/issue-discovery.md).
4. **issue-triage** — classify target issue and draft next-step guidance. Read
   [issue-triage.md](references/issue-triage.md).
5. **pr-review** — review target, then draft or explicitly create pending
   review. Read [pr-review.md](references/pr-review.md).
6. **pr-feedback** — inspect or address existing review comments. Read
   [pr-feedback.md](references/pr-feedback.md).
7. **ci-fix** — inspect failing checks and prepare focused fix context. Read
   [ci-fix.md](references/ci-fix.md).

If intent is unclear, ask for mode before GitHub writes or source edits.

## Shared Rules

- Read repository contributor docs, local instructions, and matching issue/PR
  template before drafting or publishing.
- Treat GitHub writes as separate authority: inspect and draft by default;
  create, edit, comment, label, close, submit, or resolve only when requested.
- PR URL inputs accept `https://github.com/...` only. Do not use these helpers
  for GitHub Enterprise until hostname binding is implemented.
- Write public prose like teammate: specific evidence and direct request, no
  generic significance claims, canned acknowledgement, or repeated detail.
- Use `git-toolkit` change-stack mode for commit/branch/PR-stack shape.
- Call out destructive Git risk before reset, rewrite, force-push, or branch
  deletion.
