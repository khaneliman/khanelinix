---
name: github-toolkit
description: GitHub maintainer queues, issue discovery, triage, and creation, pull-request creation and stacking, review authoring and feedback, CI check-fix workflows using gh CLI. Use for read or write work on GitHub issues, PRs, stacks, reviews, or checks.
---

# GitHub Toolkit

Route to one mode and load only named reference:

1. **issue-creation**: draft or explicitly create issue. Read
   [issue-creation.md](references/issue-creation.md).
2. **pull-request-creation**: draft or explicitly create pull request. Read
   [pull-request-creation.md](references/pull-request-creation.md).
3. **pr-stacking**: create, inspect, restructure, or merge dependent pull
   requests as a GitHub stack. Read [pr-stacking.md](references/pr-stacking.md).
4. **issue-discovery**: search, filter, rank, or summarize many issues. Read
   [issue-discovery.md](references/issue-discovery.md).
5. **issue-triage**: classify target issue and draft next-step guidance. Read
   [issue-triage.md](references/issue-triage.md).
6. **pr-review**: review target, then inspect, create, update, or delete
   current-actor reviews when explicitly requested. Read
   [pr-review.md](references/pr-review.md).
7. **pr-feedback**: inspect or address existing review comments. Read
   [pr-feedback.md](references/pr-feedback.md).
8. **ci-fix**: inspect failing checks and prepare focused fix context. Read
   [ci-fix.md](references/ci-fix.md).
9. **maintainer-queue**: collect a bounded repository queue, rank evidenced next
   actions, and route selected items. Read
   [maintainer-queue.md](references/maintainer-queue.md).

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
- Use `git-toolkit` change-stack mode to decide commit/branch slices and review
  units. Use pr-stacking mode here to execute those slices as a GitHub stack.
- Call out destructive Git risk before reset, rewrite, force-push, or branch
  deletion.
