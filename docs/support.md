# Support and Verification

## Evidence levels

Source discovery is not evaluation. Evaluation resolves options and derivations;
a native build realizes an output on its intended platform. Boot verification
starts that image in an isolated machine. Runtime verification exercises the
specific services or tools. A passing flake check does not build every fleet or
home closure. Mutable Homebrew and Flatpak installations are not fully pinned by
the flake lock.

## Configuration scope

| Outputs                            | Intended composition                                                                    | Boundaries                                                                                   |
| ---------------------------------- | --------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------- |
| `khanelinix`                       | x86_64 Linux workstation; AMD/Btrfs, gaming, development, Wayland and compute workloads | Integrated Home Manager owns activation; existing boot and memory policies retained          |
| `khanelinix` specialisation `safe` | Separately composed recovery system                                                     | Does not inherit the parent; not a package-profile permutation                               |
| `bruddynix`                        | x86_64 Linux gaming desktop; Plasma/Jovian                                              | Explicit desktop overrides retained; dormant zen/lts source is not an active specialisation  |
| `khanelilab`                       | x86_64 Linux server under preparation                                                   | Evaluation/build is not cutover or workload parity proof; no cutover in this milestone       |
| `nixos`                            | x86_64 graphical VM                                                                     | Not a generic hardware installation profile                                                  |
| `CORE-PW0D2M1A`, `VT0-IT-47-D443`  | x86_64 WSL, user `nixos`                                                                | Windows paths and work settings remain owned by the named configurations                     |
| `khanelimac`, `khanelimac-m1`      | aarch64 Darwin workstation/build machine                                                | Native Darwin required; Rosetta input patches may realize tools at evaluation time           |
| Eight `homeConfigurations`         | Named homes matching those systems                                                      | Inherit matching host context; build only, no standalone activation of live integrated users |
| `installer-minimal`, `rescue`      | Portable x86_64 UEFI images                                                             | Unsigned; no fleet disk, owner account, personal credential, cache, or builder composition   |

The `referenceSources` output preserves the ARM VM, graphical installer, and
isolated image source. It does not claim supported evaluation, native build,
boot, or runtime behavior. In particular, ARM VM source still uses obsolete
option paths. No reference-only support was broadened.

Reusable aggregates no longer select owner Git identity or fleet credentials.
SSH inventories, signer keys, builders, caches and encrypted sources are
explicit fleet/home policy. Home network modules require explicit server
addresses when enabled. Set identities before enabling programs that need them;
supply your own SOPS declarations if credentials are required. Enabling SOPS
alone does not select this repository's encrypted files.

Existing public host/home names remain unchanged, except that the two portable
images are now exported explicitly. Ambiguous cross-architecture names are
errors. WSL standalone homes now use the integrated `nixos` identity. Moving
capability caches into fleet policy changes list ordering on `bruddynix`,
`khanelinix`, `nixos`, `khanelimac`, and `khanelimac-m1`; their URL and
trusted-key multisets are unchanged.

`clamshell` is available only on Darwin and requires macOS `caffeinate`/`pmset`.
`nixos-needsreboot` is available on Linux but runs meaningfully only on a booted
NixOS installation with `/run/booted-system` and a system profile. Neither
platform metadata nor derivation evaluation establishes those runtime
conditions.

## Portable images

```bash
nix build .#installer-minimal-iso --no-link --print-out-paths
nix build .#rescue-iso --no-link --print-out-paths
```

The minimal installer uses upstream live-media hardware detection, generic
`nixos`/root console accounts, passwordless local sudo and networking. Remote
login still requires deliberately configuring authentication. Installation may
need internet access. No disk layout is preselected.

Rescue uses the same live-media boot composition with network services and cache
substitution disabled. Core recovery tools are included in its closure:
cryptsetup, ddrescue, testdisk, SMART/NVMe tools, partitioning and filesystem
tools, file, and tmux. Offline rescue does not promise an arbitrary offline
reinstallation. Recovery commands remain manual; never run a destructive repair
without understanding the target.

For isolated UEFI verification, use QEMU with OVMF, a fresh disposable copy of
`OVMF_VARS.fd`, `-nic none`, and no host disks or shared directories. Test the
actual built ISO, not only a VM configuration with similar packages. Verify
`/sys/firmware/efi`, the live-media root/store mounts, command availability, and
non-destructive tool operations. Physical USB boot is a separate evidence level.

The ISO path generates a GRUB EFI loader. This milestone does not sign it or
enroll keys. UEFI boot alone does not demonstrate Secure Boot enforcement. These
images require Secure Boot disabled; signed-image support is not provided.
Signing, trust enrollment, and firmware rejection/acceptance tests are separate
work; signed image support is deferred. No live firmware settings are changed.

## Reproducing the bounded matrix

Archive the Git-filtered checkout before evaluation so ignored scratch files
cannot alter package discovery. Stage intended new source files first. Keep the
source revision, root lockfile hash, evaluator platform/version, snapshot path,
commands and results together.

```bash
evidence="${XDG_CACHE_HOME:-$HOME/.cache}/khanelinix-reliability"
mkdir -p "$evidence"
nix flake archive --json > "$evidence/archive.json"
snapshot=$(python3 -c 'import json, sys; print(json.load(open(sys.argv[1]))["path"])' "$evidence/archive.json")
python3 tests/reliability.py "$snapshot" "$evidence/matrix"
nix fmt
nix develop --command pre-commit run --all-files
nix flake check
```

The evaluator runs serially. The matrix covers every named system and home,
active specialisations, neutral public consumers, participating profile tiers,
Darwin backend choices and an intentionally inconsistent backend assertion. It
is not an exhaustive enumeration of closures or arbitrary option combinations.
Run native Darwin checks on Darwin, including a cold evaluation-store path where
input patch realization is exercised. Linux warm-store Darwin evaluation is
regression evidence only.

`tests/native-darwin.py` creates a fresh source-only evaluator store for each
target and uses the installed native daemon as its build store. Its disposable
store accepts unsigned outputs built by that daemon, using the per-store
[`require-sigs` setting](https://nix.dev/manual/nix/2.35/store/types/local-store.html).
It does not change installed cache trust or demonstrate a cold dependency build.

Native fleet builds, image builds, UEFI boots and offline rescue operations must
be recorded separately. See [milestone evidence](reliability-milestone.md) for
actual results and gaps; do not interpret the commands above as claims that they
passed.

## Focused regression checks

The following checks are manual. They are not automatically discovered by
`nix flake check`, pre-commit, or CI. Package `checkPhase` tests and the
`skill-tests` hook are separate automated lanes. Run the relevant manual check
when changing its owners; a green flake check does not replace it.

Run from the repository root on Linux with Nix, Python 3, POSIX `sh`, Bash, Git
and ordinary GNU file utilities on `PATH`. Resolve source paths from the current
working-tree lock rather than choosing another cached revision. These commands
use Git-filtered sources, including tracked working-tree lockfile changes, and
do not update inputs:

```bash
nixpkgs=$(nix eval --impure --raw --expr '(builtins.getFlake ("git+file://" + toString ./.)).inputs.nixpkgs.outPath')
homeManager=$(nix eval --impure --raw --expr '(builtins.getFlake ("git+file://" + toString ./.)).inputs.home-manager.outPath')
niriSource=$(nix eval --impure --raw --expr '(builtins.getFlake ("git+file://" + toString ./.)).inputs.niri.outPath')
regressionScratch="${XDG_CACHE_HOME:-$HOME/.cache}/khanelinix-regressions"
mkdir -p "$regressionScratch"
```

| Behavior                                                   | Command                                                                                                                                                         |
| ---------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Credentials, suite defaults, SSH, LightDM and Dolphin      | `python3 tests/module-regressions.py "$nixpkgs" "$regressionScratch/modules"`                                                                                   |
| Shell aliases, generated commands and service environments | `python3 tests/command-regressions.py "$nixpkgs" "$homeManager" "$regressionScratch/commands"`                                                                  |
| Selective stash and Fish backup/extraction                 | `FISH=fish COMPRESS=compress SEVENZIP=7z python3 tests/terminal-recovery.py "$PWD" "$regressionScratch/recovery"`                                               |
| Terminal aliases, editor and T3 backup paths               | `python3 tests/terminal-regressions.py "$nixpkgs"`                                                                                                              |
| Terminal hooks and lazygit quoting                         | `python3 tests/terminal-data-regressions.py "$nixpkgs" "$regressionScratch/terminal-data"`                                                                      |
| Native Atuin, Yazi, Helix and WezTerm behavior             | `python3 tests/native-tool-regressions.py "$nixpkgs" "$homeManager" "$regressionScratch/native-tools"`                                                          |
| Angular language-server wrappers                           | `python3 tests/angular-wrappers.py "$nixpkgs" "$regressionScratch/angular"`                                                                                     |
| Portable btop future scheduling                            | `python3 tests/btop-future-regressions.py "$nixpkgs" "$regressionScratch/btop"`                                                                                 |
| Snowfall template DNS options and merges                   | `python3 tests/snowfall-dns-regressions.py "$nixpkgs"`                                                                                                          |
| Graphical command rendering and locker/menu flows          | `python3 tests/graphical-commands.py --nixpkgs "$nixpkgs" --home-manager "$homeManager" --niri "$niriSource" --scratch "$regressionScratch/graphical-commands"` |
| Graphical callbacks and launcher workflows                 | `python3 tests/graphical-workflows.py --scratch "$regressionScratch/workflows" --lua lua`                                                                       |
| Weather location parsing and rendered callbacks            | `python3 tests/weather-regressions.py --nixpkgs "$nixpkgs" --lua lua --scratch "$regressionScratch/weather"`                                                    |
| GNOME shortcuts and native schema types                    | `python3 tests/gnome-regressions.py "$nixpkgs" "$homeManager" "$shellSchemas" "$desktopSchemas"`                                                                |

The Fish check needs Fish, gzip, bzip2, unzip, Git, and ordinary file utilities
on `PATH`. `COMPRESS` names ncompress's `compress` executable; `SEVENZIP` must
name a `7z` executable, not `7zz`. Omitting either skips the combined `.Z`/`.7z`
fixture. Other extraction cases still run. Use `FISH=fish` without those two
variables when intentionally accepting that gap.

The Lua checks need Lua 5.4. Weather also needs Bash, jq and gawk. GNOME needs a
PyGObject-enabled Python and compiled schemas from the locked `gnome-shell` and
`gsettings-desktop-schemas` packages. Set `shellSchemas` and `desktopSchemas` to
their directories containing `gschemas.compiled`, not the package roots. The
native-tool checks build their own pinned runtime dependencies. The module check
also needs OpenSSH's `ssh`; the btop check needs `patch`; graphical command
checks need `jq`. Terminal-data and graphical workflows invoke Bash. Graphical
workflows also need `file`, `find`, `tac`, `sed`, `awk`, `getconf` and `xargs`,
alongside coreutils above. Read each runner's docstring for optional arguments.
Companion Nix, Lua, C++ and recorder files are fixtures used by these runners,
not additional entry points.

Graphical command checks evaluate the locker path but do not build it. Realize
the locked package before running that row:

```bash
nix build --impure --no-link --expr \
  "(import (builtins.toPath \"$nixpkgs\") {}).swaylock-effects"
```

The runner only requests locker help; it does not lock a desktop. The expression
uses the resolved root input, not a floating registry package.

The package runtime runner deliberately puts temporary files in its working
directory. Run it from the cache directory, with an absolute script path:

```bash
repository=$PWD
(cd "$regressionScratch" && python3 "$repository/tests/package-runtime-regressions.py" "$nixpkgs")
```

These checks evaluate focused module compositions or run tools against
disposable data. Some build wrappers or native dependencies. They do not
activate homes, start real desktop sessions, sync accounts, or demonstrate
Darwin runtime behavior. The btop check proves portable scheduling only, not
macOS sensor behavior; Snowfall DNS checks do not complete the whole scaffold.
Alternative-source options support testing an uncommitted copy and verifying
that a regression check rejects broken code. They do not select newer inputs.
