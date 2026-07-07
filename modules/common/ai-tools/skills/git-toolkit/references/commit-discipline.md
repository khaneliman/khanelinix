# Commit Discipline

Use for commit planning, message drafting, and local history cleanup.

## Core Policy

- Match repository history (`git log`) first.
- Prefer imperative, short, scoped subjects.
- Use Conventional Commit style when repo does.
- Always include a body explaining why the commit exists. One short sentence is
  fine.
- Before the first commit, inspect the full diff and state the planned commit
  split when more than one logical unit exists.
- Name the target of each planned commit: component, dependency, configuration
  surface, command, generated artifact, or integration point.
- Stage only intended hunks/files.
- Review `git diff --cached` before every commit.
- Do not bundle unrelated changes.
- Do not bundle independent changes only because they came from one user
  request.
- Ask before bundling when the split is unclear or when a technically possible
  split feels misleading.

## Atomic Commit Planning

Treat each commit as the smallest committable scope: the narrowest change that
can stand on its own, build, and tell one useful history fact. A good split is
based on dependency order and behavior, not on convenience, feature name, or the
fact that changes arrived in one request.

Before committing, write the plan as ordered commit boundaries. For each
boundary, ask:

- Can this change build or evaluate without later commits?
- Can a reviewer understand why this exists without reading later commits?
- Could this be reverted without reverting the neighboring change?
- Does this mix setup, enablement, configuration, generated output, cleanup,
  formatting, tests, or docs?

If the answer shows a narrower independent unit, split again.

After the first split, run the target-granularity check: if a commit touches
multiple independently revertible targets, split by target even when the change
type is the same. Examples of separate targets include different components,
dependencies, upstream projects, configuration surfaces, commands, skills,
generated artifacts, or integrations. Keep them together only when one target
cannot evaluate or make sense without the other.

Split these when each can stand alone:

- dependency/input additions and their required lockfile update
- package or tool exposure in a dev shell/profile
- reusable module/package/helper creation
- concrete configuration that consumes that dependency/tool
- generated snapshots, lockfiles, fixtures, or golden output
- tests that assert the new behavior
- documentation of the new workflow or feature
- host or profile enablement of that reusable piece
- client/application/package replacement
- cleanup or deletion of newly unused code
- formatting-only churn

Keep changes together only when splitting would break evaluation, leave a commit
that cannot run, or hide the actual reason for the change. State that reason
before committing.

Example split for adding a new tool:

1. `chore(flake): add namaka input`
2. `feat(devshell): expose namaka`
3. `feat(namaka): add test configuration`
4. `chore(namaka): add snapshots`

Do not collapse these into one "add namaka" commit when each step is
independently meaningful and buildable.

Example split for adding several related targets:

1. `feat(foo): add integration`
2. `feat(bar): add integration`
3. `feat(baz): add integration`
4. `feat(profile): enable integrations`

Do not collapse `foo`, `bar`, and `baz` into one setup commit just because they
serve the same user-facing goal. Different upstreams, dependencies, risks,
verification paths, or rollback paths are separate targets.

## Message CLI Safety

Never emit literal `\n` escape sequences in commit messages.

Bad:

```bash
git commit -m "line1\nline2"
```

Good:

```bash
git commit -m "feat(scope): subject" -m "body paragraph"   # multiple -m flags
git commit -F path/to/message.txt                          # file input
git commit -F-                                             # stdin (heredoc)
```

## Local History Strategy

Before committing follow-up fixes, inspect whether history edit is better:

- immediate HEAD correction: prefer `git commit --amend`
- nearby local-only regression: prefer `git commit --fixup=<target>` then
  `GIT_SEQUENCE_EDITOR=: git rebase -i --autosquash <parent>^`
  (`GIT_SEQUENCE_EDITOR=:` skips the editor — non-interactive)
- pushed/shared commits: avoid rewrite; use follow-up commit unless user
  coordinates rewrite; confirmed rewrite requires `git push --force-with-lease`

If splitting, squashing, or reordering is needed, state target history shape
before running commands.
