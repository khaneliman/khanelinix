# Adversarial Review

Use for an independent, read-only review of a commit, branch, or diff. Form a
fresh judgment from repository evidence instead of extending prior review
conclusions.

Read the `premise-review` method in `engineering-principles` first. It is the
review contract: its packet, review order, premise gate, Standards and Spec
evidence axes, scrutiny list, test-value boundary, finding format, and verdict
apply unchanged. This mode adds the Git target and clean-room dispatch. Invoke
`$software-engineering` when architecture, state, failure, or evolution premises
need its lenses; the contract's finding format and verdict stay authoritative.

## Target

- Require the repository path and a read-only command that exposes the full
  change, such as `git show <commit>` or `git diff <base>...HEAD`. Reject or
  replace any supplied inspection command that can mutate the worktree, history,
  remotes, or external state.
- Fill the contract packet from the request, commit messages, and linked issues:
  the problem and its requirement source, falsifiable author claims, hard
  constraints outside the diff, domain lenses, and the one hazard to
  sanity-check. If material input is missing, state the gap and review what can
  still be proven. Do not invent requirements.
- Inspect the full change, not a summary.

## Clean-Room Dispatch

When the harness permits, route the review to a fresh worker with only the
packet, the target artifact, repository instructions, and permission to run
read-only probes. When more than one worker reviews, give at least one a blind
brief: problem, requirements, repository context, and target, with the
author-claims field omitted. If no fresh worker exists, explicitly disregard
prior review conclusions and rebuild evidence from the repository.

Remain read-only. Do not edit files, stage changes, rewrite history, post review
comments, or change external state.
