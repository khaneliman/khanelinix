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
    hash = "sha256-mGvl1w2syfIw2z4ZtC6RcZ/gO0xZTT30K5u4QqeOiDI=";
  })
  (fetchpatch2 {
    name = "t3code-pr-10881-agent-history.patch";
    # Use the combined diff so normalization preserves new-file amendments.
    url = "https://github.com/pingdotgg/t3code/pull/10881.diff";
    # Reanchor the Grok tests, Claude imports, and agent panel text sizes
    # after upstream context drift.
    postFetch = ''
      substituteInPlace "$out" --replace-fail \
        $'@@ -212,6 +212,123 @@\n });\n \n it.layer(grokAdapterTestLayer)("GrokAdapterLive", (it) => {\n' \
        $'@@ -295,3 +295,120 @@\n'
      substituteInPlace "$out" --replace-fail \
        'it.effect("sends runtime context with the current model without changing saved prompts", () =>' \
        'it.effect("keeps runtime context out of native command arguments", () =>'
      substituteInPlace "$out" --replace-fail \
        $'@@ -6,6 +6,9 @@\n  *\n  * @module ClaudeAdapterLive\n  */\n' \
        $'@@ -7,8 +7,11 @@\n  *\n  * @module ClaudeAdapterLive\n  */\n \n import * as NodeUtil from "node:util";\n'
      # Match only removed and context lines; the PR's added lines keep their sizes.
      substituteInPlace "$out" \
        --replace-fail 'text-[.6rem]' 'text-3xs' \
        --replace-fail 'text-[.7rem]' 'text-2xs' \
        --replace-fail 'text-[.65rem] font-medium uppercase' 'text-3xs font-medium uppercase' \
        --replace-fail 'font-mono text-[.65rem]",' 'font-mono text-3xs",' \
        --replace-fail 'font-mono text-[.65rem] text-muted-foreground">' 'font-mono text-3xs text-muted-foreground">'
    '';
    hash = "sha256-AyQQnF3RNzuHYlAIqG2jql6eebZVFWtpZqVfh+FPa18=";
  })
  # Effect ignores the "preserve" decode mode #10881 relies on, which cut
  # Claude transcript records down to their type and emptied their history.
  ./fix-claude-agent-history-transcript-fields.patch
]
