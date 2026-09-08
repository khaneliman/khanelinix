# Rebased onto pingdotgg/t3code 12391bd0d38e. Order is load-bearing:
# the sidebar and identity patches extend the timeout-patched Codex runtime.
[
  # Fork bf5a88adca, including both drawer entry points and vendor chunking.
  ./perf-lazy-load-terminal-drawer.patch
  # Fork 9d8723a7ca, preserving upstream PATH cache and file-manager probing.
  ./perf-concurrent-command-resolution.patch
  # Fork 883b413cd9, migrated to the current Effect error API.
  ./fix-codex-session-start-timeout.patch
  # Fork 2a504ad066, keeping unrelated threads responsive during startup.
  ./fix-agent-queue-blocked-on-session-start.patch
  # PR #7507, squashed to its final runtime and fixture changes.
  ./fix-codex-spawned-subagent-sidebar.patch
  ./fix-codex-top-level-subagent-identity.patch
  ./desktop-attach-existing-backend.patch
]
