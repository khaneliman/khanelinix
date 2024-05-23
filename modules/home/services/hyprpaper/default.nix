{
  config,
  inputs,
  lib,
  pkgs,
  system,
  namespace,
  ...
}:
let
  inherit (lib)
    mkIf
    mkEnableOption
    types
    mkOption
    ;
  inherit (inputs) hyprpaper hypr-socket-watch;
  inherit (lib.${namespace}) mkOpt;

  cfg = config.${namespace}.services.hyprpaper;
in
{
  options.${namespace}.services.hyprpaper = {
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
        package = hyprpaper.packages.${system}.hyprpaper;

        settings = {
          preload = cfg.wallpapers;
          wallpaper = map (monitor: "${monitor.name},${monitor.wallpaper}") cfg.monitors;
        };
      };

      hypr-socket-watch = {
        enable = cfg.enableSocketWatch;
        package = hypr-socket-watch.packages.${system}.hypr-socket-watch;

        monitor = "DP-1";
        wallpapers = "${pkgs.${namespace}.wallpapers}/share/wallpapers/";
        debug = false;
      };
    };
  };
}
