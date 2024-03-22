{ config
, lib
, pkgs
, ...
}:
let
  inherit (lib) mkIf mkEnableOption types mkOption;
  inherit (lib.internal) mkOpt;

  cfg = config.khanelinix.desktop.addons.hyprpaper;
in
{
  options.khanelinix.desktop.addons.hyprpaper = {
    enable = mkEnableOption "Hyprpaper";
    enableSocketWatch = mkEnableOption "hypr-socket-watch";
    monitors = mkOption {
      description = "Monitors and their wallpapers";
      type = with types; listOf (submodule {
        options = {
          name = mkOption {
            type = str;
          };
          wallpaper = mkOption {
            type = path;
          };
        };
      });
    };
    wallpapers = mkOpt (types.listOf types.path) [
    ] "Wallpapers to preload.";
  };

  config =
    mkIf cfg.enable
      {
        services = {
          hyprpaper = {
            enable = true;
            # package = hyprpaper.packages.${system}.hyprpaper;
            package = pkgs.hyprpaper;
            preloads = cfg.wallpapers;
            wallpapers = map (monitor: "${monitor.name},${monitor.wallpaper}") cfg.monitors;
          };

          hypr-socket-watch = {
            enable = cfg.enableSocketWatch;
            package = pkgs.hypr-socket-watch;

            monitor = "DP-1";
            wallpapers = "${pkgs.khanelinix.wallpapers}/share/wallpapers/";
            debug = false;
          };
        };
      };
}
