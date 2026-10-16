# Task Branch and Worktree Cleanup

Use before creating isolated work and as soon as each worker's slice is
accepted, rejected, or abandoned, not at the end of a run. The parent owns
cleanup, including resources created by delegated workers and host-created
worktrees such as T3 `delegate_task` isolation, which the host does not remove.

## Ownership

Record each task-owned path, branch or detached HEAD, starting commit,
integration target, and worker when creating it. Use existing task notes; do not
add a repository-wide inventory for a single branch. Update the record with the
exact handoff tip. Preserve it across compaction or a pending merge queue.

Do not infer ownership from a naming prefix, age, or a merged-branch listing.
Pre-existing resources and other sessions stay outside scope unless assigned.
Use a detached worktree for read-only scratch when no branch is needed.

Each worktree is a full checkout plus its build output, so give one only to a
writer that cannot share the checkout. Before creating one, confirm that free
space on its filesystem stays above 10% of the disk, and above Nix `min-free`
where Nix is installed, after adding the checkout's size. Otherwise close out
resolved worktrees first.

## Closeout

1. Inspect worker artifacts and integrate the worker's committed tip into the
   named local target by merge, fast-forward, or cherry-pick. Verify that
   target, not just the worker checkout. A committed worker branch is not
   integration. Follow `github-toolkit` for PR merge evidence.
2. Stop or close the task's workers and processes using the owned worktrees.
   Release host-managed worktrees through the owning host when available. Never
   unlock another session's worktree or delete a live checkout.
3. From a retained checkout, run the helper for each exact owned resource.
   Preview first, then apply under the existing local-cleanup authority:

   ```sh
   python3 <git-toolkit>/scripts/cleanup.py --repo <retained-checkout> \
     --branch <owned-branch> --worktree <owned-path> \
     --expected-tip <full-handoff-sha> --target <local-integration-branch>
   ```

   Repeat with `--apply` after inspecting the manifest. This flag confirms the
   agent's inspected plan; it does not require another user confirmation. Omit
   `--worktree` for a branch-only resource, or `--branch` for a detached
   worktree. Exit 0 means a valid preview, successful apply, or already absent;
   exit 1 reports a blocked cleanup. A `ready` preview is not a cleanup receipt.
   When integration cannot be proved, such as rejected work or a landing edited
   during integration, pass `--keep-branch` instead of `--target`. It removes
   only the clean checkout and keeps the branch at its tip. Commit a failed
   worker's leftover edits on its branch first.
4. Verify each owned path is absent from `git worktree list --porcelain`, each
   owned branch is absent or recorded as retained, and the retained checkout
   remains on its intended branch with unrelated changes intact. Account for
   every ownership record. Report removed resources, or retained path/ref,
   reason, and next action.

## Integration and Preservation

The helper requires a local target branch and an unchanged full source tip.
Normal merge/fast-forward cleanup uses ancestry. For a squash or single
cherry-pick, add `--source-base <recorded-fork-sha>` and
`--landed-commit <landing-sha>`. The helper requires the landing in the target
history and an exact binary-capable diff match. This preserves whitespace,
modes, and file content; commit-message similarity is not evidence.

Conflict-resolved rebases and multi-commit rebase landings can fail this strict
check. Retain those branches until exact integration is independently proved; do
not substitute a newer source base to hide omitted changes. If cleanup needs a
manual path, inspect every source change and any post-merge commits first.

The helper refuses primary, executing, locked, unavailable, dirty, and
in-progress worktrees. It also rejects index flags that can hide tracked edits,
including sparse checkouts. Ignored files also count: inspect and remove only
known task-owned disposable outputs before retrying. Preserve unintegrated
patches, abandoned experiments with unique work, user-requested retained
resources, and open/queued PR branches, with an explicit handoff instead of
silent leftovers.

Never use `rm -rf`, forced worktree removal, blanket merged-branch deletion, or
broad pruning as task cleanup. The helper uses Git worktree removal and checks
integration before local branch deletion. Stop concurrent writers first; Git
cannot make the entire worktree/branch removal sequence transactional. Remote
deletion needs existing remote-cleanup authority and exact remote/ref
verification. Local cleanup authority does not grant a remote write.
