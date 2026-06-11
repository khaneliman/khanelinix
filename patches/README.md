# Input Patches

`lib/system/common.nix` patches selected flake inputs before system builders
evaluate them. Patching is intended for short-lived upstream backports, such as
testing a merged pull request before the pinned input updates.

Supported inputs:

- `nixpkgs`
- `nixpkgs-unstable`
- `nixpkgs-master`
- `home-manager`
- `nix-darwin`

Patch sources:

- `patches/<input>/*.patch`: local patch files, applied in sorted attr-name
  order.
- `patches/<input>/default.nix`: returns extra patch paths, derivations, or
  fetchpatch attribute sets.
- `extraInputPatches.<input>`: same shape as `default.nix`, passed directly to
  `mkSystem`, `mkDarwin`, or `mkHome`.

`mkDarwin` can patch every supported input. `mkSystem` and `mkHome` patch
`nixpkgs`, `nixpkgs-unstable`, `nixpkgs-master`, and `home-manager`; they skip
`nix-darwin` because those builders do not evaluate it.

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
