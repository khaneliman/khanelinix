# Task Plan: integrate nixpkgs Citrix changes

## Goal

Review the checked-out nixpkgs Citrix branch, map all fixes/features into
khanelinix, and prove the safest flake/config integration path with focused
evaluations and builds.

## Current Phase

Phase 9

## Phases

### Phase 1: Branch and config discovery

- [x] Resolve nixpkgs base/HEAD and exact commit stack
- [x] Inventory khanelinix nixpkgs/pkgsMaster/module wiring
- [x] Record current dirty worktree boundaries
- **Status:** complete

### Phase 2: Integration design

- [x] Map each Citrix change to package, overlay, input patch, or NixOS config
- [x] Separate required support from optional runtime tiers
- [x] Identify security and compatibility risks
- **Status:** complete

### Phase 3: Focused validation

- [x] Evaluate relevant host/module options against branch packages
- [x] Build package variants and inspect generated artifacts
- [x] Probe wrapper/service assumptions without mutating live system
- **Status:** complete

### Phase 4: Delivery

- [x] Provide exact flake/config change plan
- [x] Report verified features, gaps, and recommended implementation order
- **Status:** complete

### Phase 5: Package repairs

- [x] Fix each branch regression in an isolated worktree hunk
- [x] Create targeted fixup commits for introducing commits
- [x] Fix pre-existing `icaroot` passthru in separate ordinary commit
- **Status:** complete

### Phase 6: Repair validation

- [x] Build default and OpenSC variants
- [x] Validate udev, GStreamer, browser, PKCS#11, and USB artifacts
- [x] Verify commit targets and clean worktree
- **Status:** complete

### Phase 7: Khanelinix integration

- [x] Backport repaired package expression into `nixpkgs-master`
- [x] Select one OpenSC-enabled package through patched `getPkgsMaster`
- [x] Add reusable NixOS system-integration module
- [x] Route Home Manager to the NixOS-selected package and enable workstation
      support
- [x] Evaluate and build focused configuration outputs
- **Status:** complete

### Phase 8: Activation debugging

- [x] Diagnose `ctxusbd.service` crash loop (`libcap.so.1` not found)
- [x] Diagnose `home-manager-khaneliman.service` collision (`codex/config.toml`)
- [x] Fix ctxusbd: add `LD_LIBRARY_PATH` for `libcap` dlopen
- [x] Fix HM: remove stale codex config symlink
- [x] Re-test activation and live Citrix integration surfaces
- **Status:** complete

### Phase 9: Nixpkgs commit-message audit

- [x] Compare all 14 final commit subjects and bodies with their diffs
- [x] Check nixpkgs package commit conventions
- [x] Identify messages made stale or incomplete by fixup commits
- **Status:** complete

## Key Questions

1. How does khanelinix currently source `pkgsMaster.citrix-workspace`?
2. Can the local branch be consumed narrowly without replacing the system
   nixpkgs input?
3. Which of the 13 commits need system integration beyond the Home Manager
   module?
4. Which claims can be proven at build/eval time versus requiring an activated
   runtime test?

## Decisions Made

| Decision                                             | Rationale                                                                                                                       |
| ---------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------- |
| Review before edits                                  | User asked first for module review and required flake support; current worktrees already contain unrelated changes.             |
| Treat Claude blurb as leads                          | Exact branch diff and generated outputs remain authoritative evidence.                                                          |
| Prefer override, overlay, then input patch           | Explicit user preference; new nixpkgs input is last resort.                                                                     |
| Keep pre-existing `icaroot` fix out of branch fixups | Git blame places it in 2020 commit `fa3948a7`; attaching it to a 2026 feature commit would falsify history.                     |
| Patch existing `nixpkgs-master` input                | Smallest reproducible route after package override; the existing `getPkgsMaster` helper intentionally imports without overlays. |
| Forward NixOS package into Home Manager              | Keeps package, browser manifests, user daemon, udev rules, and root services on one derivation when package is overridden.      |
| Filter udev rules by USB option                      | Multitouch remains low-risk default; disabling USB redirection also removes the root USB hook.                                  |

## Errors Encountered

| Error                                                                                    | Attempt | Resolution                                                                               |
| ---------------------------------------------------------------------------------------- | ------- | ---------------------------------------------------------------------------------------- |
| Initial branch base used stale fork `origin/master` and produced huge unrelated range    | 1       | Switched to exact 13-commit `HEAD~13..HEAD` range.                                       |
| Full Home activation pulled unrelated Firefox/Neovim rebuilds from existing lock changes | 1       | Stopped redundant build after Citrix-specific package builds and integrated eval passed. |
| `makeShellWrapper` rejected activation-time `/run/wrappers/bin/ctxusb` in build sandbox  | 1       | Replaced it with a generated runtime launcher script and rebuilt.                        |
| Multitouch udev rule ran before `60-input-id` populated match property                   | 1       | Renamed generated rule to `61-ica-mtch.rules`; removed redundant FIDO rule.              |

## Notes

- Preserve existing `flake.lock`, `flake/dev/flake.lock`, and Firefox patch
  changes.
- No broad input update or live system activation during review.
- Bounded Citrix range is `10c27492e27a..251abe0485bc` (13 commits).
