---
name: github-toolkit
description: GitHub maintainer queues; issue discovery, triage, and creation; PR creation, walkthroughs, stacking, and babysitting; pending reviews and feedback; CI checks and fixes. Use for read or write work on GitHub issues, PRs, stacks, reviews, or checks.
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
6. **pr-review**: review target and create or update the current actor's pending
   GitHub review for the user to edit and submit, unless chat-only or read-only
   output is requested. Read [pr-review.md](references/pr-review.md).
7. **pr-feedback**: inspect or address existing review comments. Read
   [pr-feedback.md](references/pr-feedback.md).
8. **ci-fix**: diagnose failing CI and implement and verify requested fixes.
   Read [ci-fix.md](references/ci-fix.md).
9. **maintainer-queue**: collect a bounded repository queue, rank evidenced next
   actions, and route selected items. Read
   [maintainer-queue.md](references/maintainer-queue.md).
10. **pr-merge**: merge an authorized PR or finish post-merge closeout. Read
    [pr-merge.md](references/pr-merge.md). Use its closeout after stack merges
    too.
11. **pr-walkthrough**: explain a PR or prepare a reviewer guide. Read
    [pr-walkthrough.md](references/pr-walkthrough.md).
12. **pr-babysit**: watch an open PR across wakes and respond to new reviews,
    bot comments, and checks with local fixes and pending-review drafts. Read
    [pr-babysit.md](references/pr-babysit.md).

If intent is unclear, ask for mode before GitHub writes or source edits.

## Shared Rules

- Read repository contributor docs, local instructions, and matching issue/PR
  template before drafting or publishing.
- A PR review request authorizes creating or updating the current actor's
  pending review, not submitting it. Explicit chat-only, read-only, or no-post
  instructions override this default. Other GitHub writes require their own
  authority; preparing a pending review does not authorize publishing comments,
  approving, requesting changes, deleting reviews, or resolving threads.
- PR URL inputs accept `https://github.com/...` only. Do not use these helpers
  for GitHub Enterprise until hostname binding is implemented.
- Write public prose like teammate: specific evidence and direct request, no
  generic significance claims, canned acknowledgement, or repeated detail.
- Use `git-toolkit` change-stack mode to decide commit/branch slices and review
  units. Use pr-stacking mode here to execute those slices as a GitHub stack.
- Call out destructive Git risk before reset, rewrite, force-push, or remote
  branch deletion. Route verified task-owned local cleanup to `git-toolkit`;
  honor existing cleanup authority without asking again.
