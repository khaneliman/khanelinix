[
  # Fork bf5a88adca, including both drawer entry points and vendor chunking.
  ./perf-lazy-load-terminal-drawer.patch
  # Fork 9d8723a7ca, preserving upstream file-manager probing. Upstream #13669
  # now owns the PATH walk, so only editor and command probes run concurrently.
  ./perf-concurrent-command-resolution.patch
  ./desktop-attach-existing-backend.patch
  # Keep quota reads nonblocking and discard stale account limits after upstream #15198.
  ./antigravity-usage-limits.patch
  # Upstream owns #16716 host-folder browsing; retain folder-root and path regression coverage.
  ./host-folder-links.patch
]
