# Git Operating Rules

Use for safety boundaries across Git modes.

## Shared History

- Call out destructive risk before commands touching shared history or remotes:
  force push, reset, branch deletion, rebase of pushed commits.
- If uncertain whether commit is shared, inspect remotes before rewrite.
- Stop for user confirmation before destructive operations.

## Cross-Skill Boundaries

- Use `github-toolkit` for PR review comments, CI check triage, and issue
  creation.
- Keep Git logic here; keep GitHub workflow logic in GitHub toolkit.
