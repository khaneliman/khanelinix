# Pull Request Stacking

Use when work spans dependent pull requests: creating a stack, inspecting stack
state, restructuring layers, or merging a stack.

GitHub shipped native stacked pull requests on 2026-07-30, later than most model
training cutoffs. Do not answer stacking questions from prior knowledge of
Graphite, `spr`, or `ghstack` conventions; the native model differs. Verify
against `gh stack --help` or the docs when a detail here is load-bearing.

## Boundary

`git-toolkit` change-stack mode decides how to slice work into review units.
This play executes those slices as GitHub stack objects. Slice first, submit
second.

## Stack Model

A stack is two or more pull requests in one repository forming a dependency
chain. The bottom PR targets the trunk; each PR above targets the branch of the
PR below.

- **Trunk**: base of the whole stack, usually the default branch.
- **Base**: the branch one PR targets.
- **Layer**: a PR's position in the chain.

Placement rule: if code in one layer depends on code in another, the dependency
must be in the same branch or a lower one. Foundational work (shared types,
schema) goes low; dependent work (routes, UI) goes higher.

Merge requirements for every PR in the stack are determined by the bottom PR's
base branch. Branch protection, CODEOWNERS approval, and default-branch CI apply
to mid-stack PRs too.

## Availability

Requires the `github/gh-stack` extension. In this repository, add `gh-stack` to
`programs.gh.extensions` in
`modules/home/programs/terminal/tools/gh/default.nix` and rebuild.
`pkgs.gh-stack` is the official extension. Do not run `gh extension install`;
that leaves imperative state Home Manager does not own.

Exit code 9 means stacked pull requests are not enabled for the repository.

## Agent-Safe Commands

Several `gh stack` commands open a full-screen TUI and will hang a
non-interactive agent. Prefer the non-interactive path:

| Need         | Agent-safe                                                             | Avoid                                      |
| ------------ | ---------------------------------------------------------------------- | ------------------------------------------ |
| Read state   | `gh stack view --json`, `--short`                                      | bare `gh stack view` pager                 |
| Create PRs   | `gh stack submit --auto` (drafts) or `--auto --open`                   | bare `gh stack submit` editor              |
| Switch layer | `gh stack up`/`down`/`top`/`bottom`/`trunk`, `gh stack checkout <ref>` | `gh stack switch`, argumentless `checkout` |
| Merge        | `gh stack merge <pr> --squash --yes`                                   | bare `gh stack merge` prompts              |
| Restructure  | none                                                                   | `gh stack modify` is TUI-only              |

Preserve each existing PR's draft or ready state unless the request authorizes
changing it. Both `gh stack submit --open` and `gh stack link --open` mark
existing PRs ready for review too, not just new ones.

For restructuring, report the intended layer changes and the `gh stack modify`
keys to the user rather than attempting it: drop `x`, fold down `d`, fold up
`u`, insert below `i`, insert above `I`, rename `r`, reorder Shift+arrow, undo
`z`, save Ctrl+S. Reordering cannot be combined with structural edits in one
session. Follow any modify session with `gh stack submit`.

## Reading Stack State

`gh stack view --json` is the deterministic collector for a checked-out stack.
Do not reconstruct layer order from branch names or base refs by hand.

`gh pr view --json stack` does not exist, but REST PR resources expose native
stack membership without requiring a locally tracked stack:

```bash
gh api "repos/OWNER/REPO/pulls/N" \
  --jq '{number, base: .base.ref, head: .head.ref, state, draft, stack}'
```

After `submit` or `link`, re-read each PR's `stack.number`, `stack.position`,
`stack.size`, base, and head. Check the bottom-to-top order and every adjacent
base/head pair. Correct branch bases alone do not prove native membership;
`stack: null` means the PR is not registered in a native stack.

GraphQL also exposes stack membership:

```bash
gh api graphql -f query='
query($owner:String!,$repo:String!,$number:Int!){
  repository(owner:$owner,name:$repo){
    pullRequest(number:$number){
      stack{ number size baseRefName entries(first:50){ nodes{ pullRequest{ number state title } } } }
    }
  }
}' -F owner=OWNER -F repo=REPO -F number=N
```

`PullRequestStack` exposes `number`, `size`, `baseRefName`, and `entries`.
GraphQL is read-only; stack lifecycle operations are REST-only, and merging a
stack through the API requires the asynchronous merge endpoint.

## Jujutsu Checkouts

`gh stack init`, `add`, and `sync` maintain local Git branch tracking that
fights a jj working copy. When the checkout is jj-managed, use `gh stack link`
instead. It builds or extends a stack from branch names, PR numbers, or URLs
with no local tracking state, and exists for jj, Sapling, and git-town users:

```bash
gh stack link --base main <bottom-ref> <next-ref> <top-ref>
```

List arguments bottom to top. Branches are pushed automatically, existing PRs
are reused, missing ones are created with correct base chaining, and mismatched
bases are corrected. Updates are additive, so `link` never removes a PR. A
leading stack number appends to that stack. See `jj-toolkit` for the local
history side.

## Changing a Lower Layer

Commit the fix on the branch that owns it, then propagate:

```bash
gh stack rebase --upstack && gh stack push
```

Do not work around a lower-layer defect at the current layer. Scope the cascade
with `--downstack` (trunk up to current), `--upstack` (current up to top), or
`--no-trunk` (skip fetch and trunk rebase). `gh stack push` force-pushes with
`--force-with-lease` per branch and is non-atomic: passing branches update even
when another is rejected. It never creates or updates PRs.

Review bottom-up when dependencies affect the review. After propagating a
lower-layer change, re-read upper-layer checks and reassess prior approvals when
dependent behavior or assumptions changed, even if the layer diffs look
unchanged. This does not imply GitHub automatically dismisses every approval.

`gh stack init` enables `git rerere`, so conflict resolutions persist across the
repeated rebases a stack requires.

## Merging

Stacks merge bottom-up. Selecting a PR includes it plus every unmerged PR below
it; isolating a middle PR is impossible. A direct merge is all-or-nothing for
that selected range. With a merge queue, the range is enqueued together but can
land in separate groups. After landing, PRs above stay open and the next
unmerged PR is automatically rebased to target the stack base, moving it to the
bottom.

- Merge commit, squash, and rebase methods all work. Resulting history matches
  merging each PR individually from the bottom.
- Auto-merge is not supported.
- Merge queues are supported. Ejection cascades to everything above. The queue
  tolerates exceeding max group size by up to 50 percent to keep a stack
  together; larger stacks split across consecutive merge groups. With a queue on
  the base, method flags are ignored with a warning.
- Once an entire stack lands it cannot be extended. `gh stack submit` on new
  branches starts a fresh stack rooted at the trunk.

Call out before merging that lower PRs land with the selected one. State the
exact set of PR numbers that will merge.

After a merge, run the closeout in [pr-merge.md](pr-merge.md) for each confirmed
merged layer. Keep open dependents and queued layers outside cleanup scope.

## Failure Modes

| Symptom                            | Cause                                                                   | Remedy                                                                                                                                                           |
| ---------------------------------- | ----------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Merge box blocks merge             | non-linear history after a push to a lower branch or trunk moving ahead | `gh stack rebase` then `gh stack push`, or the **Rebase stack** button                                                                                           |
| Rebase or sync stops               | conflict                                                                | resolve, `git add`, then `gh stack rebase --continue`; `--abort` restores prior state. Interrupted sync restores all branches; recover with `rebase` then `push` |
| Direct stack merge fails           | a selected PR cannot merge                                              | none of the selected range lands; requery state, fix the blocker, then retry                                                                                     |
| Queue stops after some layers land | selected layers processed in separate merge groups                      | requery every selected PR; preserve confirmed landings and queued layers, then address blockers on the remaining open layers                                     |
| Ejected from merge queue           | a lower PR left the queue                                               | everything above is ejected; re-add the stack once resolved                                                                                                      |
| Unsigned commits appear            | server-side rebase commits are not signed                               | rebase locally with `gh stack rebase`, then `gh stack push`                                                                                                      |
| Mid-stack PR closed                | closed layer blocks everything above                                    | unstack on the web or restructure with `gh stack modify`, then rebuild                                                                                           |
| Modify will not start              | dirty tree, rebase underway, queued PR, or non-linear history           | clean the state; run `gh stack rebase` first                                                                                                                     |
| Stack creation fails across forks  | cross-fork stacks are unsupported                                       | no workaround; move branches into one repository                                                                                                                 |

Unstacking removes open, draft, and closed PRs; merged and queued PRs stay
stacked, so a stack containing either never fully dissolves.

## Automation Hazard

`gh stack sync` aborts on a diverged stack but still exits successfully in
non-interactive contexts. Check the output, not just the exit code. Other codes
are specific: 2 not in a stack, 3 rebase conflict, 4 API failure, 5 invalid
arguments, 6 branch in multiple stacks, 7 rebase already in progress, 8 stack
locked, 9 stacking not enabled, 10 modify session needs recovery.

## Authority

Stacking multiplies write scope: one command can push several branches, open
several PRs, or merge several PRs. Treat each as a separate authority.

- Inspect and draft by default. `submit`, `link`, `push`, and `merge` need an
  explicit request.
- Before `submit` or `link`, list the branches and the PRs that will be created.
- Before `merge`, list every PR number that will land.
- `rebase`, `push`, and the web rebase force-push existing branches and rerun
  CI. Call out that risk first.
- Unsupported surfaces: cross-fork stacks and GitHub Desktop. The feature is in
  public preview and subject to change.

## Completion Evidence

After a remote mutation, requery GitHub rather than relying on command success
or local tracking alone. Before reporting a stack clean, verify:

- the trunk, native stack number, size, and bottom-to-top PR order;
- every PR's base, head, state, draft state, and native position, including
  adjacent base/head chaining;
- current branch ancestry, no merge commits between layers, focused layer diffs,
  required checks, and any review requirements;
- any remaining conflicts, draft PRs, review or CI blockers, or pending queue
  entries. A queued PR is not a confirmed merge.

Report the stack identity, ordered PRs, and outstanding blockers. For merges,
confirm each selected PR's remote state before running closeout.

References:
[Stack APIs and webhooks](https://docs.github.com/en/pull-requests/reference/stacked-pull-requests-apis-and-webhooks),
[Stack CLI commands](https://docs.github.com/en/pull-requests/reference/stacked-prs-cli-commands).
