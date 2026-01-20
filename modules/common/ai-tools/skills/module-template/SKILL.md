---
name: nix-module-template
description: "Basic Nix module structure template. Use when creating new NixOS, Home Manager, or nix-darwin modules from scratch."
---

# Module Template

## Standard Structure

```nix
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf mkEnableOption;

  cfg = config.namespace.moduleName;
in
{
  options.namespace.moduleName = {
    enable = mkEnableOption "module description";
  };

  config = mkIf cfg.enable {
    # Configuration here
  };
}
```

## NixOS System Module

```nix
# modules/nixos/services/my-service.nix
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.services.myService;
in
{
  options.services.myService = {
    enable = mkEnableOption "My Service";
    port = lib.mkOption {
      type = lib.types.port;
      default = 8080;
    };
  };

  config = mkIf cfg.enable {
    systemd.services.my-service = {
      wantedBy = [ "multi-user.target" ];
      serviceConfig.ExecStart = "...";
    };
  };
}
```

## Home Manager Module

```nix
# modules/home/programs/my-app.nix
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.programs.myApp;
in
{
  options.programs.myApp = {
    enable = mkEnableOption "My App";
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.myApp ];
    xdg.configFile."myapp/config".text = "...";
  };
}
```

## nix-darwin Module

```nix
# modules/darwin/system/defaults.nix
{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.myproject.macosDefaults;
in
{
  options.myproject.macosDefaults = {
    enable = mkEnableOption "macOS defaults";
  };

  config = mkIf cfg.enable {
    system.defaults.dock.autohide = true;
  };
}
```

## Key Points

- Always use `cfg` pattern for accessing options
- Wrap config in `mkIf cfg.enable`
- Use `mkEnableOption` for enable flags
- Keep modules self-contained
