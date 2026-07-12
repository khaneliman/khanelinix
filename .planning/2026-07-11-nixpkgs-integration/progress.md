# Progress Log

## Session: 2026-07-11

### Phase 1: Branch and config discovery

- **Status:** in_progress
- **Started:** 2026-07-11
- Actions taken:
  - Read repository contributor canon.
  - Loaded planning, Nix-writing, and OKF-memory workflows.
  - Recorded user-supplied Claude summary as unverified leads.
  - Delegated bounded nixpkgs branch review and khanelinix wiring inventory.
  - Corrected initial stale-fork base probe to exact `HEAD~13` bounded range.
  - Confirmed 13 commits touch one package expression and current locked master
    has no conflicting Citrix changes.
  - Confirmed patch stack applies cleanly to locked `nixpkgs-master`
    `38d17cafdd30`.
  - Evaluated integrated Home Manager with command-local branch override; branch
    Citrix output selected.
  - Built package and OpenSC override; inspected generated udev, systemd,
    browser, GStreamer, PKCS#11, and USB surfaces.
  - Found multiple blockers before system integration: invalid/broad udev rules,
    incomplete PKCS#11 selection, broken passthru path, raw browser hosts,
    non-plugin flatstm library, and unreachable setuid ctxusb.
- Files created/modified:
  - `.planning/2026-07-11-nixpkgs-integration/{task_plan,findings,progress}.md`

## Test Results

| Test                       | Input                                        | Expected                                | Actual                                                                 | Status                              |
| -------------------------- | -------------------------------------------- | --------------------------------------- | ---------------------------------------------------------------------- | ----------------------------------- |
| Package build              | nixpkgs branch `.#citrix-workspace`          | Build branch package                    | `/nix/store/lndcq...`                                                  | pass                                |
| OpenSC override build      | `extraPkcs11Modules = [ opensc ]`            | Build and stage module                  | `/nix/store/whsxm...`; symlink present                                 | partial: runtime selection unproven |
| Locked-master patch check  | 13-commit diff onto `38d17cafdd30`           | Clean apply                             | `git apply --check` rc 0                                               | pass                                |
| Integrated HM eval         | command-local `nixpkgs-master` path override | Select branch package                   | `/nix/store/lndcq...`                                                  | pass                                |
| Udev validation            | three packaged rules                         | All accepted                            | USB rule fails; HID rules overly broad                                 | fail                                |
| Logging unit               | `systemd-analyze --user verify`              | Valid unit                              | pass; daemon launches                                                  | pass                                |
| Generic USB lookup         | binary disassembly                           | Reach setuid wrapper                    | hardcoded sibling `ctxusb` via `execl`                                 | fail                                |
| Full HM activation         | integrated config plus path override         | Complete build                          | reached unrelated Firefox/Neovim rebuilds from dirty lock; interrupted | not required / incomplete           |
| Repaired default build     | current nixpkgs HEAD                         | Build package                           | `/nix/store/b88clagq...`                                               | pass                                |
| Repaired OpenSC build      | current HEAD plus OpenSC override            | Select module                           | `/nix/store/gr8hmyhb...`; config selects module                        | pass                                |
| Repaired NixOS udev rules  | `services.udev.packages = [ citrix ]`        | Validate rules                          | 12/12 pass                                                             | pass                                |
| Repaired GStreamer plugins | fresh registry `gst-inspect-1.0`             | Discover both plugins                   | flatstm and ctxbeffect rc 0                                            | pass                                |
| Repaired browser hosts     | six generated manifests                      | Target wrapped hosts                    | all targets executable with ICAROOT env                                | pass                                |
| Repaired USB layout        | generated package output                     | Bridge sibling lookup to setuid wrapper | launcher plus `ctxusb.real` present                                    | pass                                |

### Phase 5: Package repairs

- **Status:** complete
- Actions taken:
  - Loaded git change-stack and commit-discipline workflow.
  - Mapped six branch defects to introducing commits.
  - Confirmed `icaroot` passthru bug predates branch and requires ordinary
    commit.
  - Created targeted fixups for GStreamer, USB, udev, browser hosts, PKCS#11,
    and feature documentation.
  - Created standalone `citrix-workspace: fix icaroot passthru` commit.

### Phase 6: Repair validation

- **Status:** complete
- Actions taken:
  - Built default and OpenSC package variants.
  - Built NixOS udev-rules derivation with repaired Citrix package.
  - Verified GStreamer discovery, browser wrapper environments, PKCS#11
    selection, USB launcher layout, and passthru path.
  - Kept nixpkgs worktree clean with fixups left unsquashed as requested.

### Phase 7: Khanelinix integration

- **Status:** complete
- Actions taken:
  - Restored plan and reread contributor/module-writing canon.
  - Chose patched `nixpkgs-master`; no new input and no overlay plumbing
    required.
  - Delegated systemd/setuid contract and module-pattern discovery.
  - Added repaired Citrix package patch and upstream MIT license under
    `patches/nixpkgs-master`.
  - Added NixOS integration for FUSE, PC/SC, filtered udev rules, `ctxusbd`, and
    setuid `ctxusb`.
  - Added Home Manager package option, `ctxcwalogd`, and Chromium native
    messaging registration.
  - Forwarded the NixOS-selected package into Home Manager to prevent package
    drift.
  - Enabled generic USB redirection on the `khanelinix` workstation.
  - Proved USB opt-out removes daemon, wrapper, and USB udev hook.
  - Completed `nix flake check --no-build` for all compatible flake outputs.

## Phase 7 Test Results

| Test                         | Expected                                        | Actual                                  | Status |
| ---------------------------- | ----------------------------------------------- | --------------------------------------- | ------ |
| `nix flake check --no-build` | All compatible outputs evaluate                 | `all checks passed`                     | pass   |
| Shared package eval          | NixOS and HM select one OpenSC build            | both `/nix/store/gr8hmyhb...`           | pass   |
| Enabled USB eval             | Service and setuid wrapper use repaired package | `ctxusbd` and `ctxusb.real` selected    | pass   |
| Enabled udev build           | Multitouch and USB rules only                   | `61-ica-mtch.rules`, `85-ica-usb.rules` | pass   |
| Disabled USB eval/build      | No service/wrapper/USB hook                     | only `61-ica-mtch.rules` remains        | pass   |
| Formatting and patch hygiene | Nix format and clean patch                      | `nix fmt` and `git diff --check` pass   | pass   |

## Error Log

| Timestamp  | Error                                                                    | Attempt | Resolution                                                                |
| ---------- | ------------------------------------------------------------------------ | ------- | ------------------------------------------------------------------------- |
| 2026-07-11 | Stale fork base generated unrelated nixpkgs history                      | 1       | Used exact `HEAD~13` branch range.                                        |
| 2026-07-11 | Full HM build expanded into unrelated dirty-lock rebuilds                | 1       | Interrupted only this build; retained focused Citrix validation evidence. |
| 2026-07-11 | `makeShellWrapper` required activation-time wrapper during sandbox build | 1       | Generated launcher script directly and rebuilt.                           |
| 2026-07-11 | Multitouch rule preceded systemd input classification                    | 1       | Moved rule to priority 61 and removed redundant FIDO rule.                |

## 5-Question Reboot Check

| Question             | Answer                                                               |
| -------------------- | -------------------------------------------------------------------- |
| Where am I?          | Phase 6 complete                                                     |
| Where am I going?    | Khanelinix integration after handoff                                 |
| What's the goal?     | Safely integrate and test local nixpkgs Citrix changes in khanelinix |
| What have I learned? | See findings.md                                                      |
| What have I done?    | Reviewed, repaired, committed, and validated Citrix package stack    |
