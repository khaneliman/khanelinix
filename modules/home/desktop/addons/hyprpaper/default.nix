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
  inherit (inputs) hyprpaper hypr-socket-watch;
  inherit (lib.internal) mkOpt;

  cfg = config.khanelinix.desktop.addons.hyprpaper;
in
{
  options.khanelinix.desktop.addons.hyprpaper = {
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
        preloads = cfg.wallpapers;
        wallpapers = map (monitor: "${monitor.name},${monitor.wallpaper}") cfg.monitors;
      };

      hypr-socket-watch = {
        enable = cfg.enableSocketWatch;
        package = hypr-socket-watch.packages.${system}.hypr-socket-watch;

        monitor = "DP-1";
        wallpapers = "${pkgs.khanelinix.wallpapers}/share/wallpapers/";
        debug = false;
      };
    };

    systemd.user.services.hyprpaper.Service.Restart = lib.mkForce "always";
  };
}
