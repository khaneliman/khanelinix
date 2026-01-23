{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  inherit (lib.khanelinix) disabled enabled;

  cfg = config.khanelinix.programs.graphical.wms.niri;
in
{
  options.khanelinix.programs.graphical.wms.niri = {
    enable = mkEnableOption "niri";
    settings = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Configuration to pass through to the niri module.";
    };
  };

  imports = [
    ./apps.nix
    ./binds.nix
    ./variables.nix
    ./workspace-rules.nix
    ./window-rules.nix
  ];

  config = mkIf cfg.enable {
    home = {
      packages = with pkgs; [
        grim
        light
        playerctl
        slurp
        swaybg
        wl-clipboard
      ];
    };

    khanelinix = {
      programs = {
        graphical = {
          bars = {
            ashell = lib.mkDefault enabled;
            waybar = lib.mkDefault disabled;
          };

          launchers = {
            anyrun = enabled;
            vicinae = enabled;
          };

          screenlockers = {
            swaylock = enabled;
          };
        };
      };

      suites = {
        wlroots = enabled;
      };

      theme = {
        gtk = enabled;
        qt = enabled;
      };
    };

    programs.niri.settings = {
      hotkey-overlay.skip-at-startup = true;
    }
    // cfg.settings;

    khanelinix.services.niri-wallpaper-watch = {
      enable = true;
      wallpapers = lib.khanelinix.theme.wallpaperPaths {
        inherit config pkgs;
        names = config.khanelinix.theme.wallpaper.list;
      };
    };
  };
}
