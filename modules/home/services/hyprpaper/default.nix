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
            name = mkOption { type = str; };
            wallpaper = mkOption { type = path; };
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
          wallpaper = map (monitor: "${monitor.name},${monitor.wallpaper}") cfg.monitors;
          splash = false;
        };
      };

      hypr-socket-watch = {
        enable = cfg.enableSocketWatch;
        package = hypr-socket-watch.packages.${system}.hypr-socket-watch;

        monitor = "DP-1";
        wallpapers = "${pkgs.khanelinix.wallpapers}/share/wallpapers/";
        debug = false;
      };
    };
  };
}
