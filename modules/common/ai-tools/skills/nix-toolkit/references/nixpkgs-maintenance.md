# Nixpkgs Maintainer Work

## Package Update Triage

- Start clean on refreshed upstream. Run the selector without auto-commit;
  inspect diffs. `DONE` without a diff needs no branch.
- Compare versions/stable-release status and search open PRs by package/version,
  checking duplicate files. Reject prereleases, downgrades, and owned updates
  before branching/building.
- Use one branch/atomic commit per package. Rerun its updater without further
  delta; build the derivation and direct wrapper/consumer where applicable.
- Rebase local-only branches onto one final upstream snapshot; repeat checks and
  record the base.

## Vim/Neovim Plugin Updater Runs

### Current Evidence And Source Failures

Record the exact base commit the updater ran against, not a moving ref. Exit
zero or a semantic `ok` can hide stale data. Scan fresh logs for `ERROR`,
failed-plugin summaries, fetch exceptions, and `Keeping current plugin data`.

- An occupied `updates/<ecosystem>` branch can abort worktree creation before
  tasks start. Nonzero exit/setup traceback overrides semantic `ok`. Corroborate
  copied logs with timestamps, worktrees, tips/reflogs, and saved-base history.
- Inspect `git worktree list --porcelain`; do not detach another checkout or
  move its branch underneath it. Recreate missing worktrees only in authorized
  scope, with recoverable tips and the exact base; otherwise report not
  PR-ready.
- Retry transient fetch failures. For an absent upstream tag, preserve the
  package and record a narrow skip with fetch evidence, not a permanent bypass.
  Try root `main.lua` and `<pname>/main.lua` in preferred order with a 404
  fallback, regardless of repository owner.
- Rerun degraded commands and inspect fresh logs/diffs, even if now unchanged.
  Derive changed attributes, build exact targets, require clean worktrees, and
  separate intentional skips from failures.

### Tag Ordering

Recent-tag ordering is creation time, not version order. For auto-branch plugins
with an existing source tag, compare normalized current/candidate releases using
nixpkgs ordering before resolving the ref. Keep the newer release; preserve
fallbacks for missing, non-release, or invalid tags. Restore generated version
and hash, test newer-major versus recent older-series ordering, and build
`python3Packages.nixpkgs-plugin-update` for Ruff/mypy. Rerun the ecosystem;
require no unintended generated delta or downgrade.

### Partial Grammar Generation

Plugin metadata can commit before nvim-treesitter grammar generation fails. A
rerun skips grammars when evaluated/discovered revisions now match. Confirm the
partial commit and absent grammar update; retry the failed fetch first.

In the updater-owned Vim worktree, temporarily restore only nvim-treesitter's
version, revision/tag, and hash in
`pkgs/applications/editors/vim/plugins/generated.nix` from the plugin commit's
parent. Do not commit the rollback. Run `nix run .#vimPluginsUpdater`; require
metadata restoration, a grammar update commit, and a clean tree. Check changed
attributes and build parsers/tests with:

- `nix-build -A vimPlugins.nvim-treesitter.parsers`
- `nix-build -A vimPlugins.nvim-treesitter.tests`

Exit zero without grammar generation is not recovery.

## Neovim Plugin Advice Contract

`pluginAdvisedLua` collects `passthru.initLua` only from direct normalized
plugin entries: optional entries contribute, duplicates can repeat advice,
dependencies alone do not. With `autoconfigure` enabled, the nixpkgs wrapper
appends advice after user Lua/VimL; disabling it suppresses advice. Other
consumers differ.

- Use `runtimeDeps` for expected normal-operation tools, including an intended
  namesake/default backend: fzf-lua expects fzf despite supporting `fzf_bin` or
  skim.
- Do not force optional integrations into closures. Use guarded
  `passthru.initLua` for selectable Nix-specific executable/library/cache/data
  paths, not expected runtime tools.
- Preserve explicit values, merge configuration, defer function-valued settings,
  and make advice idempotent. Avoid `require()`/`setup()` to preserve lazy
  loading. Audit unconditional globals even when packaged code has a fallback.
- Pin sources, trace settings' read timing, and test packaged operations with
  explicit overrides. Builds/assigned globals are not runtime proof. Do not
  probe wrapper `VIMINIT` with `-u NONE` or `--clean`: both suppress advice.

## Review And Publication

### Exact-HEAD Gates

Check PR bodies/comments for prior results before rerunning covered systems.
Select systems. Serialize reviews sharing a Git common directory to avoid shared
review/upstream ref collisions.

Give each attempt a fresh durable `XDG_CACHE_HOME`; preserve the actual report
root beneath it, not an assumed `NIXPKGS_REVIEW_ROOT`. Parse `report.json`:

- `commit` equals HEAD; result keys exactly match requested systems.
- Each system's `failed`, `broken`, `non-existent`, and `blacklisted` lists are
  empty. Check package lists against changed attributes; measure maximum `built`
  length before choosing the target branch.
- Any history rewrite, including message-only changes, requires a full rerun.

Before authorized publication, require the PR still be a draft and its head SHA
match the report commit. Post from the preserved root; read back the comment to
verify target, commit, systems/packages, and no failed-build section.

### Scoped Review-Request Automation

Prefer a local poller for r-ryantm PRs directly requesting the authenticated
user: search `author:r-ryantm user-review-requested:@me` with `gh pr list`. Key
state by PR number/head SHA. Use a full non-shallow checkout; run
`nixpkgs-review pr` with `--no-shell --checkout commit` to avoid base rebuilds.
`--post-result` requires authority and the gates above. Use a user
timer/LaunchAgent.

Webhooks need a GitHub App or repository-admin deployment; personal
notifications are not webhooks. Filter `pull_request` / `review_requested` by
author/reviewer, verify signatures, and enqueue an isolated runner. Never run
untrusted PR code in a privileged `pull_request_target` job with secrets. No
automatic approve or merge.
