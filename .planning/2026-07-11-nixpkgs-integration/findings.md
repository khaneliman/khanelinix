# Findings & Decisions

## Requirements

- Review current checked-out nixpkgs branch module/package changes.
- Map every new Citrix fix/feature to khanelinix flake and module support.
- Verify Claude's claims, including HM-only status, `pkgsMaster` blocker, udev
  rules, PKCS#11 support, and USB redirection gap.
- Run focused eval/build/runtime-safe probes where practical.
- Preserve unrelated local changes.

## Research Findings

- User-supplied Claude summary claims 13 Citrix commits exist only on local
  nixpkgs branch.
- Summary says current khanelinix Citrix module consumes
  `pkgsMaster.citrix-workspace`.
- Claimed low-risk integration: package udev rules plus OpenSC PKCS#11 module
  and ccid pcscd plugin.
- Claimed unresolved integration: `ctxusbd` root service and setuid `ctxusb`,
  because store `ICAROOT` cannot directly contain setuid wrapper.
- Existing khanelinix worktree was already dirty before review: modified
  `flake.lock`, modified `flake/dev/flake.lock`, added Firefox patch.
- Nixpkgs branch `citrix-workspace` HEAD is `251abe0485bc`; exact 13-commit base
  is `10c27492e27a`.
- All 13 commits modify only `pkgs/by-name/ci/citrix-workspace/package.nix` (138
  insertions, 35 deletions).
- Current khanelinix `nixpkgs-master` lock is `38d17cafdd30`; branch base is its
  ancestor and the Citrix package file is unchanged between base and lock. Patch
  stack should therefore apply without content drift.
- Khanelinix Home Manager module imports a fresh overlay-free `pkgsMaster`
  package set and installs `pkgsMaster.citrix-workspace`; normal khanelinix
  overlays do not affect it.
- Citrix is enabled only for `homes/x86_64-linux/khaneliman@khanelinix` in
  current config.
- User preference: package override first, shared overlay second, input-tree
  patch third, new nixpkgs input last.
- Command-local
  `--override-input nixpkgs-master path:/home/khaneliman/Documents/github/nixpkgs`
  evaluates integrated Home Manager to branch package
  `/nix/store/lndcq...-citrix-workspace-26.04.0.105`.
- Branch package and OpenSC override both build. OpenSC symlink lands in
  `$ICAROOT/PKCS#11`, but `AuthManConfig.xml` leaves `PKCS11module` empty;
  staging is proven, functional selection is not.
- `services.pcscd.enable` already adds `pkgs.ccid` to both plugins and udev
  packages. Explicit `services.pcscd.plugins = [ pkgs.ccid ]` is redundant.
- Whole-package udev integration is currently blocked: `85-ica-usb.rules` has
  invalid obsolete `OPTIONS+="last_rule"` and an absolute `/usr/bin/logger` RUN
  command rejected by NixOS udev rule validation.
- Shipped `50-ica-mtch` and `69-ica-hid` rules grant `uaccess` broadly to every
  input event and every hidraw node, not narrowly to Citrix/FIDO devices.
  Security scope needs review before enablement.
- `passthru.icaroot = "${placeholder "out"}/..."` evaluates without
  `/nix/store`; modules must use `${pkg}/opt/citrix-icaclient` until package is
  fixed.
- Browser manifests are not activated merely by installing package. Their
  targets are raw, unwrapped `NativeMessagingHost` and `UrlRedirector` binaries
  with unresolved ICAROOT expectations; do not link manifests yet.
- `ctxcwalogd.service` verifies and daemon launches, but packaged unit requires
  registration and explicit enablement.
- `libctxbeffect.so` is discoverable in a wrapper-like GStreamer environment.
  `libgstflatstm1.0.so` is not a dynamic GStreamer plugin; adding it to plugin
  search path does not expose it.
- Generic USB is definitively incomplete: `VDGUSB.DLL` resolves sibling
  `$ICAROOT/ctxusb` and calls `execl`; it does not search PATH. `libredirect`
  does not intercept `execl`, so `security.wrappers.ctxusb` alone or
  NIX_REDIRECTS cannot bridge it.
- Clean USB packaging design: retain raw binary as `ctxusb.real`, put launcher
  at `$ICAROOT/ctxusb` that execs `/run/wrappers/bin/ctxusb`, and set NixOS
  wrapper source to `ctxusb.real`.
- `passthru.icaroot` is pre-existing, blamed to `fa3948a7c5bf1` from 2020; it
  has no honest target among the 13 Citrix feature commits.
- Repaired default package builds as
  `/nix/store/b88clagq...-citrix-workspace-26.04.0.105`.
- Repaired OpenSC override builds as
  `/nix/store/gr8hmyhb...-citrix-workspace-26.04.0.105`; symlink and
  `AuthManConfig.xml` default both select `opensc-pkcs11.so`.
- Generated udev package now contains only `61-ica-mtch.rules` and
  `85-ica-usb.rules`; direct verification is 2/2 and NixOS udev derivation
  verification is 12/12.
- Both browser manifests target wrapped hosts exporting required Citrix
  environment.
- `gst-inspect-1.0 flatstm` and `ctxbeffect` both return success with correct
  plugin filenames.
- `ctxusb` is a runtime launcher to `/run/wrappers/bin/ctxusb`; `ctxusb.real`
  remains patched ELF for `security.wrappers` source.
- `passthru.icaroot` now equals the built output ICAROOT using
  `finalAttrs.finalPackage`.
- Khanelinix now applies the repaired package diff through
  `patches/nixpkgs-master/citrix-workspace.patch`; no new flake input is
  required.
- Both NixOS and Home Manager evaluate to
  `/nix/store/gr8hmyhbzfcnffmsb7lddba454vykbs8-citrix-workspace-26.04.0.105`
  with OpenSC selected.
- NixOS forwards its selected package into integrated Home Manager, so later
  package overrides cannot silently split system and user integration.
- Udev registration uses a filtered derivation: multitouch is always present
  when Citrix is enabled; `85-ica-usb.rules` exists only when generic USB
  redirection is enabled.
- USB-disabled evaluation has no `ctxusbd` service, no `ctxusb` wrapper, and a
  udev output containing only `61-ica-mtch.rules`.
- Enabled host evaluation has the setuid wrapper sourced from `ctxusb.real`, the
  vendor-compatible forking daemon contract, the Chromium native hosts, and
  `ctxcwalogd` user service.
- Live `ctxusbd` is active with zero restarts and uses the same Citrix package
  selected by the current flake; its post-fix journal contains no libcap or
  crash errors.
- Live `ctxcwalogd` is active and has handled actual `gst_read` client sessions.
- The generated setuid wrapper is root-owned mode 4555 and embeds the expected
  `ctxusb.real` source; the package sibling launcher reaches it through
  `/run/wrappers/bin/ctxusb`.
- Both deployed Citrix udev rules pass `udevadm verify`. The attached YubiKey
  already receives `uaccess` and a user ACL from standard rules, so the removed
  broad Citrix HID rule is unnecessary on this host.
- Citrix's configured OpenSC module enumerates the attached YubiKey PIV token
  through the active PC/SC service.
- Both Chromium native-host manifests are live, valid, executable, and target
  wrappers exporting the same package ICAROOT.
- Fresh-registry `gst-inspect-1.0` loads both `flatstm` and `ctxbeffect` when run
  with the exact Citrix wrapper environment.
- The active Home Manager generation matches current evaluation and the
  previously colliding Codex config is now a managed store symlink.

## Technical Decisions

| Decision                                                       | Rationale                                                                                                                                                                                                   |
| -------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Prefer narrow package routing if feasible                      | Avoid replacing primary system nixpkgs merely to test one package stack.                                                                                                                                    |
| Require generated-output inspection                            | Citrix behavior depends on package paths, wrappers, udev rules, and HM module output rather than source claims alone.                                                                                       |
| Do not force ordinary overlay for current `getPkgsMaster` path | `mkInputPackageSets` imports master with `overlays = [ ]`; overlay would need explicit plumbing and still cannot conveniently add a new package-function argument without copying/replacing the expression. |
| Enable repaired system wiring on `khanelinix`                  | Package repairs removed the udev, browser-host, PKCS#11, and sibling-wrapper blockers found during initial review.                                                                                          |
| Skip explicit `pcscd.plugins = [ pkgs.ccid ]`                  | `services.pcscd.enable` already supplies ccid in current NixOS.                                                                                                                                             |
| Keep hardware/session tests manual                             | Device attachment and ICA-session behavior can change remote state or require interactive Citrix/browser UI; build and live host infrastructure are proven independently.                                  |

## Issues Encountered

| Issue | Resolution |
| ----- | ---------- |

## Resources

- `/home/khaneliman/Documents/github/nixpkgs`
- `/home/khaneliman/khanelinix/flake.nix`
- `/home/khaneliman/khanelinix/patches/README.md`

## Visual/Browser Findings

- None.
