# Input Patches

This directory is only for flake input patches. For existing nixpkgs package
patches, pins, overrides, or build flag changes, use `overlays/` as described in
`CONTRIBUTING.md`.

`lib/system/common.nix` patches selected flake inputs for the system and home
builders and for platform-specific package, image, and documentation outputs.
Patching is intended for short-lived upstream backports, such as testing a
merged pull request before the pinned input updates.

Supported inputs:

- `nixpkgs`
- `nixpkgs-unstable`
- `nixpkgs-master`
- `home-manager`
- `sops-nix`
- `stylix`
- `nix-darwin`
- `nix-rosetta-builder`

Patch sources:

- `patches/<input>/*.patch`: local patch files, applied in sorted attr-name
  order.
- `patches/<input>/default.nix`: returns extra patch paths, derivations, or
  fetchpatch attribute sets.
- `extraInputPatches.<input>`: same shape as `default.nix`, passed directly to
  `mkSystem`, `mkDarwin`, or `mkHome`.

`mkDarwin` can patch every supported input. `mkSystem` and `mkHome` patch
`nixpkgs`, `nixpkgs-unstable`, `nixpkgs-master`, `home-manager`, `sops-nix`, and
`stylix`; they skip `nix-darwin` and `nix-rosetta-builder` because those
builders do not evaluate them.

When `nixpkgs` has patches, Stylix is re-evaluated against the patched tree even
if Stylix has no patches of its own. Home Manager, sops-nix, nix-darwin, and
nix-rosetta-builder do the same for `nixpkgs-unstable`. In particular, this
ensures the Rosetta builder bakes its VM image from patched nixpkgs.

Public module exports use the locked, unpatched inputs. The consumer's platform
is not available when imports resolve, so the exports do not pick a builder or
apply input patches. Use `mkSystem`, `mkDarwin`, or `mkHome` with an explicit
`system` when the configuration needs these patches.

Entries with `url` are converted to `pkgs.fetchpatch2` by default:

```nix
{ ... }:
[
  {
    url = "https://github.com/owner/repo/pull/123.patch";
    hash = "sha256-...";

    # Optional; defaults to "fetchpatch2".
    fetcher = "fetchpatch";

    # Optional; extra attributes pass through to selected fetcher.
    stripLen = 1;
  }

  ./local.patch
]
```

Use `hash = lib.fakeHash;`, build once, then copy the `got:` hash from the
fixed-output derivation failure.
