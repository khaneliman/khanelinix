# SketchyBar deferred-window lifetime crash

## Finding

On October 11, 2026, four SketchyBar crash reports on `khanelimac` showed
`EXC_CRASH / SIGABRT`, an invalid free on the main dispatch queue, and SkyLight
transaction callbacks waiting in `__window_apply_frame_block_invoke`.

An isolated sanitizer reproduction confirms a lifetime defect in the deployed
SketchyBar window code. Closing and reopening an embedded popup window before a
pending resize callback arrives can free the embedded window as though it were
an independent allocation. Destroying its containing allocation before callback
delivery also produces a use-after-free.

The reproduction matches the reported dispatch stack. It establishes a real
defect and a verified fix for that defect, not the exact event sequence behind
each historical crash. The reports do not identify the invalid pointer or its
allocation history. The original live trigger remains unknown.

This is separate from the March investigation of
[WindowServer instability](darwin-windowserver-instability.md). Neither
WindowServer nor Dynamic Island restarted during the afternoon episode. No Lua
error, memory exhaustion, or font-patch defect was established as its cause.

## Deployed provenance

Read-only inspection ran locally because this session was already on
`khanelimac`; `khanelimac-ts` did not resolve from this host.

- Service: `gui/501/org.nix-community.home.sketchybar`.
- Launch wrapper: `/nix/store/b7ybb3m3kbd80hrwnhsbhch6n22bii7q-sketchybar`.
- Package: `/nix/store/05v0c7i2qmn5kdpb16nysm8b8rkh30i2-sketchybar-2.24.0`.
- Package derivation:
  `/nix/store/ahcmiq3irqqs9nc4kqizpfhsn5nhcj1f-sketchybar-2.24.0.drv`.
- Source: tag `v2.24.0`, commit
  [`6284ee816601486ace33ca48a0271832eec6de35`](https://github.com/FelixKratz/SketchyBar/commit/6284ee816601486ace33ca48a0271832eec6de35).
- Source NAR hash: `sha256-5tyc/yYzdV/3JTtujuj7le/14XkC7TlN/nZg7tOZsNg=`.
- Exactly two deployed source patches: font PR 826 at
  `fc2cdcfabf764c5f7d8695ee7573a8f26c8bbe89` and PR 828 at
  `84a6ad36089070c8b3b07d7885375f177d72e951`.
- Binary UUID: `C71523EE-E6CD-35B0-A5B7-CFAA1C49FE6B`, matching all four
  reports.
- Current main config uses Yabai and comes from Home Manager files at
  `/nix/store/d51c5xxpmdwna96dyw2ni4917l3c48n6-home-manager-files`.

Reports inspected under `~/Library/Logs/DiagnosticReports/`:

- `sketchybar-2026-10-11-085129.000.ips`, captured at 08:51:27 CDT.
- `sketchybar-2026-10-11-085129.ips`, captured at 08:51:28 CDT.
- `sketchybar-2026-10-11-134415.ips`, captured at 13:44:14 CDT.
- `sketchybar-2026-10-11-134416.ips`, captured at 13:44:16 CDT.

Launchd reported three runs, two successive crashes, and terminating signal 6.
The replacement PID 48105 started at 13:44:25 CDT. The inspected stdout log
records configuration loads around the restarts, but not a decisive trigger.

## Owning-layer correction

In the deployed
[`src/window.c`](https://github.com/FelixKratz/SketchyBar/blob/6284ee816601486ace33ca48a0271832eec6de35/src/window.c),
`window_apply_frame` increments a window reference count and schedules a
post-decode callback holding its raw pointer. `window_close` calls
`window_clear`, resetting the count to one. A late callback sees the reopened
surface, decrements the reset count, and calls `window_destroy`, which frees the
pointer. Popup and bar windows are embedded in their owners, so this is not
valid storage ownership. Their owners can also be freed independently of
callback references.

Disassembly confirms that the destruction branch tail-calls `free`. That
explains why the report can show malloc immediately above
`_dispatch_client_callout`, without a SketchyBar frame in between. The worker
offset `__window_apply_frame_block_invoke+176` follows its call to
`dispatch_sync` on the main queue.

The package patch moves callback ownership to the separately allocated surface:

- Retain the surface before scheduling each resize callback.
- On close, tear down resources immediately and invalidate that surface.
- Let callbacks release the retained surface even when it has been closed.
- Never capture window storage, free embedded windows, or touch a reopened
  window's replacement surface from an old callback.
- Preserve latest-frame rendering for callbacks within the same open lifetime.

Reference changes and resource access remain serialized on the main queue; the
SkyLight worker only forwards its captured surface to that queue. No new atomic
counter or per-widget workaround is needed. Remove this patch when an upstream
release corrects the lifetime problem. Upstream
[`515046e8a150d6b8767a8a6dd624824eaafa2c8b`](https://github.com/FelixKratz/SketchyBar/blob/515046e8a150d6b8767a8a6dd624824eaafa2c8b/src/window.c)
still contained the same lifetime logic when inspected on October 11, 2026.

## Verification

The native Darwin regression runner takes an evaluated package derivation,
copies its source, applies its exact patch list, and compiles the real relevant
window functions and complete surface implementation with AddressSanitizer and
UndefinedBehaviorSanitizer. SkyLight and layer calls are inert; CoreGraphics
bitmap contexts and libdispatch are real. It never starts SketchyBar or creates
WindowServer windows.

```sh
python3 tests/sketchybar-window-lifetime.py \
  /nix/store/ahcmiq3irqqs9nc4kqizpfhsn5nhcj1f-sketchybar-2.24.0.drv \
  "$XDG_CACHE_HOME/khanelinix/sketchybar-tests" --expect-bug

nix build .#darwinConfigurations.khanelimac.pkgs.sketchybar --no-link
fixed_drv=$(nix eval --raw .#darwinConfigurations.khanelimac.pkgs.sketchybar.drvPath)
python3 tests/sketchybar-window-lifetime.py "$fixed_drv" \
  "$XDG_CACHE_HOME/khanelinix/sketchybar-tests"

nix build \
  .#darwinConfigurations.khanelimac.config.home-manager.users.khaneliman.programs.sketchybar.finalPackage \
  --no-link

nix build .#darwinConfigurations.khanelimac.system --no-link
```

The deployed derivation reproduces `bad-free` and `heap-use-after-free` on the
main dispatch queue. The patched derivation passes normal resize, reopen,
multiple callbacks across reopen, embedded-owner destruction, heap-window
destruction, closed-window completion, and fallback dispatch. All seven cases
finish with no stale flush, sanitizer error, or retained tracked allocation. The
package, Home Manager wrapper, and full `khanelimac` Darwin system build; the
package version check passes. Formatting and independent review pass.

Repository-wide hooks passed except the unchanged nix-toolkit test
`test_accepts_boolean_flag_with_option`, which returned exit 141 in the
`skill-tests` hook. The invocation used `PAGER=cat MANPAGER=cat NIX_PAGER=cat`
to prevent interactive Nix help pagers. No skill source or tests were changed.

Live verification is deliberately outstanding. Nothing was pushed, deployed,
activated, or restarted. After separately authorized activation, normal use must
establish whether this fixes every recurring desktop crash; isolated checks do
not test real SkyLight callback timing or visual rendering.
