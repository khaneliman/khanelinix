# Reusable Nix Modules

## Standard Wrapper Shape

```nix
{ config, lib, ... }:
let
  cfg = config.khanelinix.category.name;
in
{
  options.khanelinix.category.name.enable =
    lib.mkEnableOption "description";

  config = lib.mkIf cfg.enable {
    # implementation
  };
}
```

- Keep `cfg` aligned with module's owning `config.khanelinix.*` option path.
- Follow directory taxonomy in option path. Use deeper subcategories when path
  represents them, for example `khanelinix.programs.terminal.tools.<name>`.
- Check `lib.khanelinix` and flattened helpers on `lib` before adding local
  helper logic.

## Option Ownership

- Add `khanelinix.*` wrapper options when behavior must vary across hosts/users
  or needs explicit toggle/customization.
- Configure upstream NixOS, nix-darwin, or Home Manager options directly when no
  repository-level choice exists. Do not wrap only for visual consistency.

## Executable References

- For aliases and generated config expected to follow active user profile, add
  package to `home.packages` or `environment.systemPackages` and use command
  name.
- Use `lib.getExe`/`lib.getExe'` when fixed store path is part of service,
  activation, dependency-closure, or reproducibility contract.

## File Layout

- Treat roughly 200 lines or multiple independently owned programs as split
  signal, not hard limit.
- Keep `default.nix` as owner/router and move cohesive pieces into named sibling
  modules, following existing patterns such as `shells/` and theme submodules.
