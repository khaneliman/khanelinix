# User Configurations

## Layout and Ownership

- `homes/<arch>/<user>@<host>/default.nix` owns user identity, monitor layout,
  suite selection, per-user overrides, and per-user secret paths. Move shared
  user defaults into `modules/home/`.

```nix
let
  inherit (lib.khanelinix) enabled;
in
{
  khanelinix = {
    roles.developer = enabled;
    suites.desktop = enabled;
  };
}
```

## State Version

- Treat `home.stateVersion` as migration state, not current Home Manager release
  marker.
- Set during initial home creation. Change only with explicit migration plan and
  release-note review.

## Validation

```bash
nix build '.#homeConfigurations."<user>@<host>".activationPackage'
```

When home is embedded in NixOS or Darwin configuration, validate owning system
too.
