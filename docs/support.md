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
