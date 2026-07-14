# Host Configurations

## Layout and Ownership

- `systems/<arch>/<host>/default.nix` owns hardware facts, hostname/network
  identity, boot configuration, archetype selection, and host-only overrides.
  Move reusable behavior into `modules/`.
- Keep generated NixOS hardware output in the host's `hardware.nix`.

```nix
let
  inherit (lib.khanelinix) enabled;
in
{
  khanelinix = {
    archetypes.workstation = enabled;
    services.ollama.enable = true; # host-only override
  };
}
```

## State Version

- Treat NixOS `system.stateVersion` and Darwin `system.stateVersion` as
  migration state, not current release marker.
- Set during initial host creation. Change only with explicit migration plan and
  release-note review.

## Validation

```bash
nix build '.#nixosConfigurations.<host>.config.system.build.toplevel'
nix build '.#darwinConfigurations.<host>.system'
```

Use command matching host platform; do not evaluate unrelated fleet by default.
