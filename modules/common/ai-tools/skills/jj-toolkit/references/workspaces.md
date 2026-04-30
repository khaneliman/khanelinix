# Workspaces Reference

## Mental model: workspaces vs git worktrees

Git worktrees are separate checkouts tied to branches. Each worktree locks its
branch — no other worktree can check it out. Changes made in a worktree must be
merged or rebased back into the main worktree's branch through the normal
branch-integration workflow.

jj workspaces are fundamentally different:

- **Shared repo.** All workspaces point to the same `.jj/repo/` store. There is
  no separate clone, no separate history, no separate refs.
- **Shared operation log.** Every `jj` command in any workspace creates an
  operation entry visible to all workspaces. `jj op log` in workspace A shows
  operations performed in workspace B.
- **No merge-back.** Commits created in one workspace are immediately visible in
  every other workspace. The main workspace can rebase, squash, bookmark, or
  push those commits — no pull, fetch, or merge needed.
- **No branch-locking.** Multiple workspaces can check out the same commit.
  There's no concept of a branch being "in use" by another worktree.
- **Lock-free concurrency.** You can run `jj` commands simultaneously in
  different workspaces without corruption. The operation log handles divergence
  gracefully.

Think of workspaces as multiple cursors into the same repository. Each cursor
(`@`) is independent, but they all see the same commit graph.

## Stale working copies

When one workspace rewrites another workspace's `@` (e.g., by rebasing an
ancestor), the affected workspace becomes **stale**. jj detects this on the next
command and prompts:

```
The working copy is stale (since N operations ago).
Hint: Run `jj workspace update-stale` to recover.
```

Running `jj workspace update-stale` checks out the rewritten version of the
working-copy commit. If the original operation was lost, jj creates a recovery
commit preserving the working directory contents.

## Operation log sharing

Each operation records the complete repo state including:
- All bookmark positions
- All Git refs and repo heads
- The working-copy commit **for every workspace**

This means `--at-op` lets you inspect any workspace's historical state. The
operation log is the mechanism that makes instant cross-workspace visibility
possible.

## Sparse checkouts

Each workspace maintains independent sparse patterns. This enables monorepo
workflows where different workspaces check out different subsets of the tree:

```bash
# In workspace "frontend": only check out frontend code
jj sparse set --add frontend/ --add shared/

# In workspace "backend": only check out backend code
jj sparse set --add backend/ --add shared/
```

## Colocated repo caveats

In colocated jj/git repos, `jj workspace add` creates a workspace that may not
have full git interop. The new workspace gets its own `.jj/` but may not have a
`.git/` — meaning git-based tooling (editors, CI scripts) may not work there.
Plan accordingly if you need git compatibility in all workspaces.

## Use cases

- **Parallel testing.** Run a long test suite in one workspace while continuing
  development in another. Both see the same commits.
- **Multi-agent work.** Give each agent its own workspace for isolated file
  changes while sharing the same commit graph.
- **Cross-commit comparison.** Check out different revisions in different
  workspaces and use standard filesystem tools (diff, IDE) to compare.
- **Isolated experiments.** Try risky refactors in a disposable workspace. If
  it works, the commits are already in the main repo. If not, forget the
  workspace and abandon the commits.
