{
  config,
  inputs,
  lib,
  pkgs,
  system,

  ...
}:
let
  inherit (lib)
    mkIf
    mkEnableOption
    types
    mkOption
    ;
  inherit (inputs) hypr-socket-watch;
  inherit (lib.khanelinix) mkOpt;

  cfg = config.khanelinix.services.hyprpaper;
in
{
  options.khanelinix.services.hyprpaper = {
    enable = mkEnableOption "Hyprpaper";
    enableSocketWatch = mkEnableOption "hypr-socket-watch";
    monitors = mkOption {
      description = "Monitors and their wallpapers";
      type =
        with types;
        listOf (submodule {
          options = {
            name = mkOption {
              type = str;
              description = "Monitor name (e.g. DP-1, HDMI-A-1).";
            };
            wallpaper = mkOption {
              type = path;
              description = "Wallpaper image path for this monitor.";
            };
            fitMode = mkOption {
              type = types.enum [
                "contain"
                "cover"
                "tile"
                "fill"
              ];
              default = "cover";
              description = "How the wallpaper fits this monitor (contain, cover, tile, fill).";
            };
            timeout = mkOpt types.int 30 "Timeout between each wallpaper change.";
          };
        });
    };
    wallpapers = mkOpt (types.listOf types.path) [ ] "Wallpapers to preload.";
  };

  config = mkIf cfg.enable {
    services = {
      hyprpaper = {
        enable = true;

        settings = {
          preload = cfg.wallpapers;
          wallpaper = map (monitor: {
            monitor = monitor.name;
            path = monitor.wallpaper;
            fit_mode = monitor.fitMode;
            inherit (monitor) timeout;
          }) cfg.monitors;
          splash = false;
        };
      };

      hypr-socket-watch = {
        enable = cfg.enableSocketWatch;
        package = hypr-socket-watch.packages.${system}.hypr-socket-watch;

        monitor = "DP-1";
        wallpapers = lib.khanelinix.theme.wallpaperDir {
          inherit config pkgs;
        };
        debug = false;
      };
    };
  };
}
