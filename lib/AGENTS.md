# Custom Library

## When to Add Helpers

- Add helper for demonstrated reuse, shared pure logic, or behavior that becomes
  materially clearer as named abstraction.
- Keep one-off and module-specific logic with owning module.
- Keep helpers deterministic and explicit about inputs.

## Export Surfaces

- `lib/default.nix` defines flake-level `self.lib.<category>` exports.
- `lib/overlay.nix` defines extended nixpkgs `lib` visible inside NixOS,
  nix-darwin, and Home Manager modules.
- Update both when new category must be available through flake outputs and
  module arguments. Avoid adding flattened alias unless repeated module use
  justifies it.

## Current Namespaces

- `base64`: encoding helpers
- `file`: repository paths, directory scanning, recursive imports
- `module`: option helpers, `enabled`/`disabled`, package profiles, merge
  priorities
- `system`: NixOS, Darwin, and Home Manager builders plus patched-input helpers
- `theme`: color schemes, wallpaper paths, SCSS compilation
- `overlay`: extended nixpkgs library surface

Do not copy exhaustive function inventory here; source and export snapshot own
that list.

## Usage

```nix
let
  inherit (lib.khanelinix) enabled mkOpt;
in
{
  khanelinix.suites.desktop = enabled;
  sops.defaultSopsFile = lib.getFile "secrets/default.yaml";
}
```

Flake builders use `self.lib.system.mkSystem`, `mkDarwin`, and `mkHome`.

## Validation

- Add behavioral coverage in `lib/tests/default.nix`.
- Keep `lib/snapshot-tests/_snapshots/lib-exports` authoritative through Namaka.

```bash
nix-unit --flake .#tests
namaka check
```
