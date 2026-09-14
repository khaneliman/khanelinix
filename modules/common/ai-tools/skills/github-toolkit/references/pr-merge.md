# Pull Request Merge and Closeout

Use for an authorized merge or cleanup after a PR has actually merged. An open
PR is not merge authority. A merge request does not authorize deleting unrelated
branches or changing repository-wide branch deletion settings.

## Merge

1. Read the exact PR, head SHA, base branch, checks, and dependencies. Record
   the local task-owned branch/worktree and its tip before merging.
2. Use the requested merge method and repository rules. Match the reviewed head
   with `gh pr merge <number> --match-head-commit <sha>` and the selected
   method. Use pr-stacking mode when the PR belongs to a dependent stack.
3. Read back the exact PR's `state`, `mergedAt`, `mergeCommit`, `headRefOid`,
   `headRefName`, and `baseRefName` with
   `gh pr view --repo <owner/repo> --json`. A successful command, enabled
   auto-merge, or queue entry is not a merge. Preserve queued/open resources and
   record the pending closeout obligation.

## Closeout

Once readback confirms `MERGED`, fetch the exact base remote and fast-forward
the designated local integration branch when safe. Preserve unrelated local
changes and divergent commits; do not reset the main checkout to make cleanup
pass. Verify the landing in that local branch and run relevant target checks.

Invoke `git-toolkit` cleanup mode for the exact task-owned resources. Close
workers and remove linked worktrees before deleting their branches. For a
squash, retain the original source base and head plus the returned merge commit
as integration evidence. Reject local branch tips advanced past the merged PR
head until those additional commits are accounted for.

`gh pr merge --delete-branch` requests local and remote branch deletion; it is
not a complete linked-worktree cleanup workflow. Use it only with authority for
both deletions. Otherwise handle the owned local resources separately. If remote
deletion is authorized, verify the exact remote head still matches the merged PR
head and is not needed by an open dependent PR. Delete only that ref with an
expected-SHA lease, then verify absence. A remote already removed by repository
policy is a successful no-op, not a reason to retry deletion.

For partial stack merges, clean only confirmed merged layers no longer needed by
open dependents. Keep the remaining stack's worktrees and refs intact.

Finish with merged PR/landing identity and cleanup results. Name any retained
path/ref, blocker, and next action. Do not report merge-and-cleanup completion
while owned leftovers remain unaccounted for.

Reference:
[GitHub CLI merge options](https://cli.github.com/manual/gh_pr_merge).
