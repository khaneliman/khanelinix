# Focused native Home Manager and locked Niri rendering, without a host.
{
  nixpkgs,
  homeManager,
  niri,
  root ? ../.,
  repo ? root,
}:
let
  pkgsBase = import nixpkgs { system = builtins.currentSystem; };
  baseLib = pkgsBase.lib;
  lib = (import (homeManager + "/modules/lib/stdlib-extended.nix") baseLib) // {
    inherit
      (
        (import (repo + "/lib/file") {
          inputs.nixpkgs.lib = baseLib;
          self = root;
        })
      )
      getFile
      ;
    khanelinix = (import (repo + "/lib/module") { inputs.nixpkgs.lib = baseLib; }) // {
      userDir =
        _: _: fallback:
        "/home/fixture/${fallback}";
      theme.wallpaperPath = _: "/home/fixture/wallpaper.png";
    };
  };
  # Capture the native render before building; no compositor validation hook runs.
  pkgs = pkgsBase // {
    writeTextFile = args: (pkgsBase.writeTextFile args) // { renderedText = args.text; };
    writeText = name: text: (pkgsBase.writeText name text) // { renderedText = text; };
    khanelinix = {
      codexbar-cli = pkgsBase.hello;
      codexbar-waybar = pkgsBase.hello;
    };
  };
  inputs = { };
  kdl = import (niri + "/kdl.nix") { inherit lib; };
  binds = import (niri + "/parse-binds.nix") { inherit lib; };
  docs = import (niri + "/generate-docs.nix") { inherit lib inputs; };
  settings = import (niri + "/settings.nix") {
    inherit
      lib
      inputs
      kdl
      binds
      docs
      settings
      ;
  };
  launchers = builtins.listToAttrs (
    map
      (name: {
        inherit name;
        value.enable = name == "rofi";
      })
      [
        "vicinae"
        "anyrun"
        "walker"
        "sherlock"
        "rofi"
      ]
  );
  graphical = root + "/modules/home/programs/graphical";
  hm = import (homeManager + "/lib") { inherit lib; };
  evaluate =
    swayEnabled: hyprEnabled: satty:
    (hm.homeManagerConfiguration {
      inherit pkgs;
      extraSpecialArgs = { inherit lib pkgs; };
      modules = [
        settings.module
        (graphical + "/wms/niri/binds.nix")
        (graphical + "/wms/sway/binds.nix")
        (graphical + "/addons/wlogout")
        (repo + "/modules/home/programs/graphical/screenlockers/swaylock")
        {
          options.khanelinix = {
            programs.graphical =
              builtins.listToAttrs (
                map
                  (name: {
                    inherit name;
                    value = lib.mkOption { type = lib.types.attrs; };
                  })
                  [
                    "launchers"
                    "wms"
                    "bars"
                  ]
              )
              // {
                addons.satty = lib.mkOption { type = lib.types.attrs; };
              };
            services = lib.mkOption { type = lib.types.attrs; };
            theme = lib.mkOption { type = lib.types.attrs; };
          };
          config = {
            home = {
              username = "fixture";
              homeDirectory = "/home/fixture";
              stateVersion = "25.11";
            };
            khanelinix = {
              programs.graphical = {
                inherit launchers;
                wms = {
                  niri.enable = true;
                  sway.enable = true;
                };
                addons = {
                  satty.enable = satty;
                  wlogout.enable = true;
                };
                screenlockers.swaylock.enable = swayEnabled;
                bars.waybar.resetTimeFormat = "local";
              };
              services = {
                voxtype.enable = false;
                sops.enable = false;
              };
              theme.wallpaper.lock = "fixture";
            };
            programs = {
              hyprlock.enable = hyprEnabled;
              waybar = {
                enable = true;
                settings = [ { "custom/power" = (waybar cfg)."custom/power"; } ];
              };
              niri.settings.workspaces = builtins.listToAttrs (
                map (i: {
                  name = toString i;
                  value = { };
                }) (lib.range 1 9)
              );
            };
            wayland.windowManager.sway = {
              enable = true;
              checkConfig = false;
              config = {
                modifier = "Mod4";
                terminal = "kitty";
              };
            };
          };
        }
      ];
    }).config;
  cfg = evaluate true true true;
  waybar =
    config:
    import (graphical + "/bars/waybar/modules/custom-modules.nix") {
      inherit config lib pkgs;
    };
in
{
  niri = {
    argv = lib.mapAttrs (_: v: lib.toList v.action.spawn) (
      lib.filterAttrs (_: v: v.action ? spawn) cfg.programs.niri.settings.binds
    );
    kdl = cfg.programs.niri.finalConfig;
    swappy = (evaluate true true false).programs.niri.settings.binds."Ctrl+Alt+Print".action.spawn;
  };
  sway = {
    binds = cfg.wayland.windowManager.sway.config.keybindings;
    rendered = cfg.xdg.configFile."sway/config".source.renderedText;
    grace = cfg.programs.swaylock.settings.grace;
  };
  wlogout = cfg.xdg.configFile."wlogout/layout".source.renderedText;
  waybarRender = cfg.xdg.configFile."waybar/config".source.value;
  menus =
    map
      (
        bits:
        let
          c = evaluate (builtins.elemAt bits 0) (builtins.elemAt bits 1) true;
        in
        {
          inherit bits;
          wlogout = (builtins.head c.programs.wlogout.layout).action;
          waybar = (waybar c)."custom/power".menu-actions.lock;
        }
      )
      [
        [
          true
          true
        ]
        [
          true
          false
        ]
        [
          false
          true
        ]
        [
          false
          false
        ]
      ];
  packages = {
    swaylock = lib.getExe cfg.programs.swaylock.package;
    hyprlock = lib.getExe cfg.programs.hyprlock.package;
  };
}
