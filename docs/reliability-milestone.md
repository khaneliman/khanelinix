# Reliability Milestone Evidence

## Baseline and boundaries

Work started from clean revision `2a70eea42597343fba8710fe0304a13150621019` on
October 4, 2026. Its root lockfile had SHA256
`d1acaaa1a8a231c5f34ead58360b635f8eb304a0c9e03310d8a75bb585a030c0`. Baseline
discovery returned six NixOS systems, two Darwin systems, eight homes, and no
library-test failures. The existing review inventories and consumer probes were
rechecked against that same revision before implementation.

At the user's request, the local stack was rebased onto remote revision
`99cab143a`. All fourteen implementation patches replayed unchanged. Equivalent
historical commits were already present remotely; the older local lock update
was redundant except for an older Home Manager pin, so the remote pin was
retained. The rebased lockfile SHA256 is
`30f105b9514c1a0703810e8b60bb6f9c8bd9af9790829ebede17cc4136047b4f`. Relative to
the pre-rebase tree, only that pin and Claude's mutable-settings flag changed.
Earlier host checks below are identified by snapshot and are not substitutes for
rebased verification.

The Linux evaluator/build host was `khanelinix`, x86_64 Linux, Nix 2.35.2,
running kernel `7.2.7-zen1`. Native Darwin evaluation used `khanelimac-m1`,
macOS 15.7.4, arm64, Nix 2.35.2. Evaluations were serialized. Builds retained
installed concurrency and platform-specific memory policy. Command-level
substituter overrides used the official cache to avoid unavailable private
endpoints; they did not change fleet configuration.

This task issued no host or standalone-home activation commands. The workstation
generation observed during final checks was `4wdpjzs7gfjbgpay7z43c4waz3c1zdm0`,
different from the audit baseline `k58vqix3hwqi6rwrbw9rwdi1ghja7v22`. Its
standalone Home Manager profile remains absent. No push, publication, lab
cutover, host disk operation, key enrollment, or firmware change was performed.

## Confirmed corrections and retained limits

Cross-architecture discovery could overwrite a hostname; qualified internal keys
and explicit public-name collision errors correct that defect. Public module
aggregates lacked complete composition, not merely entry files. They now
provision upstream modules, extended arguments, package policy, overlays, and
integrated Home Manager forwarding.

Standalone homes lacked matching host context and definition priorities. They
now reuse the matching package set, shared modules, `osConfig`, and home-option
definitions. WSL identity drift and missing Stylix provisioning were confirmed
defects. Curated cursor ownership remains intentional. Development AI-tool
overrides and neutral Waybar defaults also exposed concrete conflicts/type
errors and received separate corrections.

Personal Git identity, encrypted sources, SSH topology, builders, caches, and
private service endpoints now belong to fleet/home configurations. Preservation
probes compared eight systems' cache/key multisets, eight homes' active
credentials/calendars/mount settings, and all 32 lab container workloads.
Inactive settings were checked only where they represent a retained capability,
not treated as active runtime behavior.

Internal constructors remain fleet-specific. Named standalone homes deliberately
depend on their matching system composition. Homebrew and Flatpak retain their
intended mutable behavior. Source-only ARM and other image definitions remain
unverified references. These are design limits or intentional differences, not
claims of universal reuse.

## Native build and image evidence

Before rebase, the full Linux workstation closure built from immutable source
`/nix/store/xw41xwvf498i2vknb46piswikf5xqp3r-source`:

```bash
nix build path:/nix/store/xw41xwvf498i2vknb46piswikf5xqp3r-source#nixosConfigurations.khanelinix.config.system.build.toplevel \
  --no-link --print-out-paths --option substituters https://cache.nixos.org/
```

The realized output was
`/nix/store/gk24jwr84j83ljhaczh9rfxm86cp13h4-nixos-system-khanelinix-26.11.20261003.a7868a7`.
Its recursive closure contains 6,637 paths and 79,583,512,560 NAR bytes. This is
a built candidate measurement, not the previously deployed closure and not an
estimate of savings from removing applications.

The rebased workstation also built successfully from
`/nix/store/427r44b584r0ssrxklwdv7m5v5494qvx-source` using the same command. Its
realized output is
`/nix/store/ln2z6i435x8a1ywaqmfrp02bczz69761-nixos-system-khanelinix-26.11.20261003.a7868a7`,
with 6,637 paths and 79,583,637,056 NAR bytes. Neither build was activated.

After the independent-review corrections, nine native Linux roots built from
`/nix/store/6rr4aac8ziwyhh6mny7xgrzvyp1lg50l-source`: the workstation, all six
Linux standalone homes, and the neutral NixOS and Home Manager consumers. The
workstation output was
`/nix/store/bsxnd513g4kf2f3d5rsys91s1w1f0nql-nixos-system-khanelinix-26.11.20261003.a7868a7`,
with 6,637 paths and 79,583,644,928 NAR bytes. Its active `safe` specialisation
is included in that realized closure. These builds did not activate any output.

Both portable x86_64 ISO outputs built natively. Exact staged-output checks
matched those artifacts before the image commit, now `0b875a928`. After rebase,
both output paths still matched the built and booted artifacts exactly:

| Image             | Realized store output              | Isolated evidence                                                                                                      |
| ----------------- | ---------------------------------- | ---------------------------------------------------------------------------------------------------------------------- |
| Minimal installer | `8ms3jj674lhcqkj8dj1wml08hargkd5z` | Actual ISO booted with UEFI, live root/store mounts, only loopback                                                     |
| Rescue            | `8hyh0ckfi9x24gh513bs4vwzrxkcrjpc` | Same boot checks; network services inactive; offline tool execution, CD recovery copy and store integrity verification |

The tests used QEMU 11.1.1 with KVM, q35, two virtual CPUs, 4 GiB RAM, OVMF
202608, and fresh disposable variables for each boot. No host disks, network
adapters, or shared directories were attached. Rescue used ddrescue to copy 64
KiB from its read-only CD to a newly created guest RAM-root file and verified
size and SHA256. It invoked cryptsetup, testdisk, SMART/NVMe, partitioning,
filesystem, file, and tmux tools, then ran
`nix-store --verify --check-contents`. It did not exercise destructive recovery
or physical USB boot.

An additional installer boot passed with TCG and exercised
`nixos-install --help` and `nixos-generate-config --help` with noninteractive
pagers. Its first KVM attempt timed out before reaching Linux; this does not
replace the earlier successful KVM boot or establish a physical firmware defect.

These are unsigned UEFI images. Loader construction does not configure signing
or enrollment. Read-only inspection of the deployed workstation reported
`SecureBoot=0`, `SetupMode=0`; that does not establish key contents or a
firmware acceptance/rejection test. Signed images and enforcement testing remain
deferred.

## Native Darwin evaluation

Both rebased Darwin targets passed on the M1 Mac from immutable source
`/nix/store/427r44b584r0ssrxklwdv7m5v5494qvx-source`, each in its own fresh
source-only evaluation store. The stores began with 77 source paths and no
derivations. Evaluation added 22,150 paths for `khanelimac` and 5,315 for
`khanelimac-m1`, taking 77.56 and 8.30 seconds respectively. The Rosetta patch
import was exercised natively. Installed daemon dependencies could be warm; this
proves cold evaluator composition, not cold dependency compilation.

Both targets passed again after the review corrections from source
`6rr4aac8ziwyhh6mny7xgrzvyp1lg50l`, with the same source-only seeding and path
counts. Native evaluation took 64.41 seconds for `khanelimac` and 7.61 seconds
for `khanelimac-m1`. Their derivation paths matched the Linux regression matrix;
the native runs, not that match, establish Darwin evaluator behavior.

Both complete Darwin systems also built on the M1 from that corrected source.
The realized outputs were
`/nix/store/bmxwl7rcdfr0z0i564si1l0s19rswkxa-darwin-system-26.11.4cff07d` for
`khanelimac` and
`/nix/store/n5flypxizg6dwrpsyg4x8zcy4mxbrliy-darwin-system-26.11.4cff07d` for
`khanelimac-m1`. Their recursive closures contain 4,116 paths / 45,348,352,728
NAR bytes and 790 paths / 6,842,357,112 NAR bytes respectively. Dependencies
could be warm or substituted; Codex 0.160.0 compiled locally and passed its
executable version check. Neither system was activated.

The primary configuration's Rosetta Linux image dependency was realized with the
Linux host's existing ARM binfmt emulation and copied to the native builder.
This does not establish support or boot verification for the reference ARM VM.
The final native build used a command-level local-builder selection after shared
builder transfer attempts stalled; installed builder and concurrency policy was
not changed.

```bash
python3 tests/native-darwin.py "$snapshot" "$evidence/native-cold"
```

Run this on Darwin after archiving the exact snapshot and locked inputs onto
that host. Scratch evaluator stores are removed after evidence is recorded;
shared daemon sources/build outputs are not garbage-collected.

`clamshell` was realized through the existing native Darwin builder policy and
its read-only `info`/`status` commands ran on the M1 Mac. `nixos-needsreboot`
built on Linux and its version/dry-run checks ran on the booted workstation.
Neither test changed sleep policy or system generations.

## Follow-up consumer and build checks

Independent review prompted focused corrections to unmanaged Nix access,
explicit LAN cache handling, per-home identity arguments, empty host context,
Darwin library selection, and manual Stylix integration. Twelve neutral-consumer
cases passed from source `cgf847z7zvayrqv55kzf61yn4mnjalv2`. All eight fleet
systems retained their allowed-user lists and cache/key multisets when compared
with rebased source `427r44b584r0ssrxklwdv7m5v5494qvx`.

The native Darwin build exposed a mutable SketchyBar patch hash and Copilot's
sandbox-denied OpenSSL configuration probe. Immutable patch commits and a
Darwin-only version-check environment corrected those failures. SketchyBar
2.24.0 and Copilot 1.0.91 built natively and passed their executable version
checks. Installed wrappers and runtime environment policy were not changed.

## Bounded regression coverage

All 55 accepted matrix cases passed against source
`6rr4aac8ziwyhh6mny7xgrzvyp1lg50l`. The initial run had 51 passes and four
failures in the parity probe: it read a cursor name even when Home Manager's
cursor submodule was disabled. The corrected probe reran all eight homes and
passed. The original failure logs and successful rerun are retained; the initial
batch itself did not exit successfully.

Coverage includes every named system, the active `safe` specialisation, every
exported home, both supported images, nine core/standard/maximal profile cases,
explicit overrides, neutral NixOS/Darwin/Linux-home/Darwin-home consumers,
multi-user integrated identity, WSL and host-context parity, disabled optional
inputs, explicit LAN caches, unmanaged Nix access, and automatic/manual Stylix
composition. Darwin backend cases cover `none`, Colima, Docker Desktop, and a
contradictory backend selection with its expected assertion. Discovery collision
tests and platform metadata checks also passed. This does not establish that
arbitrary option combinations build or operate correctly.

The public-consumer flake checks capture root inputs instead of the development
partition's older inputs. Their JSON manifests retain dependencies on evaluated
derivation files without requesting those derivations' outputs. Both Linux
manifest checks built from source `pj6569q1pn1msscdkk0pax9lzrypp2lg`; inspection
of their build graphs confirmed that distinction. Full closure builds are
recorded separately above.

On native Darwin, the neutral-consumer and standalone-home manifest checks plus
both complete system checks passed from source
`rq99l6cw0gbqg05y4qqzmg1shl1klr77`. Separate native builds then realized the
neutral Darwin system, neutral Darwin home, and both named Darwin standalone
homes. Together with the six Linux homes above, all eight named homes have
native build evidence. No activation package was executed.

Required checks exposed two additional catalogue issues. ACME's staging default
referenced an argument no current constructor supplies; it now defaults to
production, while an explicit staging selection still selects the staging
server. Both neutral regressions passed. Darwin's user-dependent log defaults
need explicit catalogue context, so the documentation fixture uses synthetic
user `docs`. The complete HTML catalogue built with generated indexes for all
three module families. The direct `nix-unit --flake .#tests` command passed 129
assertions, representing 43 library cases at the root and under two system keys;
this is not native platform evidence.

`namaka check` passed with the configured `nix flake check --print-build-logs`
subprocess after the catalogue corrections and README formatting. The first
attempt's catalogue errors and formatting failure are retained separately.
Formatting, parsing, library and snapshot checks do not replace the native
closure builds or image boot evidence above.

## Remaining verification

Primary `khanelimac` SSH access timed out, so its live Colima, Homebrew,
session, and service behavior has not been verified. Native builds on the M1 Mac
are not substitutes for those runtime checks.

The latest LAN probe exited 255 after the eight-second connection timeout; the
Tailscale route also timed out. Reproduce the access check with:

```bash
ssh -o BatchMode=yes -o ConnectTimeout=8 khaneliman@khanelimac.local uname -m
```

Once access is restored, inspect the existing Colima VM, Docker context/server,
Homebrew installations, and session/service state, then exercise a disposable
container using the selected backend. Do not activate a candidate as part of
that check. The milestone is not fully verified while this required runtime
evidence is missing.
