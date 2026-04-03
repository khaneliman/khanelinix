# Derivation Style

Package definitions should be boring, explicit, and easy to patch.

## Preferences

- Prefer the narrowest packaging helper that matches the ecosystem.
- Use `nativeBuildInputs` for build-time tools and `buildInputs` for target
  libraries.
- Keep `pname`, `version`, `src`, and patching logic easy to scan.
- Prefer `substituteInPlace --replace-fail` over ad-hoc `sed` or `perl` where
  practical.
- Prefer `fetchpatch2` for upstream patches when a stable patch URL exists.

## Decision Rule

1. If a helper like `buildGoModule` or `rustPlatform.buildRustPackage` fits,
   prefer it over a raw `mkDerivation`.
2. If you are adding a tool needed only during the build, put it in
   `nativeBuildInputs`.
3. If you are adding a library needed by the built software at compile or link
   time, put it in `buildInputs`.
4. If patching is local and mechanical, use `substituteInPlace`.
5. If the derivation is growing many unrelated helper variables, simplify it.

```nix
postPatch = ''
  substituteInPlace src/config.rs \
    --replace-fail '"/usr/bin/env"' '"${pkgs.coreutils}/bin/env"'
'';
```
