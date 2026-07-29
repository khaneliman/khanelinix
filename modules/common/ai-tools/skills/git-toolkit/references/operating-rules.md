# Git Operating Rules

Use for safety boundaries across Git modes.

## Branch Names

- Follow repository documentation and existing branch history when they define a
  naming convention.
- When repository canon is silent, choose a concise semantic name. Do not add a
  provider-identity prefix such as `agent/`, `codex/`, or `claude/` merely
  because an AI agent created the branch.
- Use a provider or automation prefix only when the user, repository, or
  execution environment explicitly requires one.

## Shared History

- Call out destructive risk before commands touching shared history or remotes:
  force push, reset, branch deletion, rebase of pushed commits.
- If uncertain whether commit is shared, inspect remotes before rewrite.
- Stop for user confirmation before destructive operations.

## Cross-Skill Boundaries

- Use `github-toolkit` for PR review comments, CI check triage, and issue
  creation.
- Keep Git logic here; keep GitHub workflow logic in GitHub toolkit.
