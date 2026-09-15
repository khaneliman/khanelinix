{ fetchpatch2 }:
# Rebased onto pingdotgg/t3code e22040dfc190. Order is load-bearing:
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
  # Emit session exit on signals so the next turn can resume its saved thread.
  ./fix-codex-signal-exit-recovery.patch
  ./desktop-attach-existing-backend.patch
  (fetchpatch2 {
    name = "t3code-pr-11594-chat-width.patch";
    url = "https://github.com/pingdotgg/t3code/pull/11594.patch";
    hash = "sha256-syM7uEsYLPBmeWOlP2M5VJKYR/uU4yBqU8aUxT79mtY=";
  })
  (fetchpatch2 {
    name = "t3code-pr-10881-agent-history.patch";
    # Use the combined diff so normalization preserves new-file amendments.
    url = "https://github.com/pingdotgg/t3code/pull/10881.diff";
    # Reanchor the Grok tests and retain the blank line before Claude imports.
    postFetch = ''
      substituteInPlace "$out" --replace-fail \
        $'@@ -212,6 +212,123 @@\n });\n \n it.layer(grokAdapterTestLayer)("GrokAdapterLive", (it) => {\n' \
        $'@@ -235,3 +235,120 @@\n'
      substituteInPlace "$out" --replace-fail \
        $'@@ -6,6 +6,9 @@\n  *\n  * @module ClaudeAdapterLive\n  */\n' \
        $'@@ -7,7 +7,10 @@\n  *\n  * @module ClaudeAdapterLive\n  */\n \n'
    '';
    hash = "sha256-L84M41UL6IvBKgQNKIYxJFByqNrqlKDD4lNedgvTcFQ=";
  })
]
