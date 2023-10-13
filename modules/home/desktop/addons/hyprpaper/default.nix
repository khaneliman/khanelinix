{ config
, lib
, pkgs
, ...
}:
let
  inherit (lib) mkIf mkEnableOption types concatStringsSep mkOption getExe;
  inherit (lib.internal) mkOpt;

  cfg = config.khanelinix.desktop.addons.hyprpaper;
in
{
  options.khanelinix.desktop.addons.hyprpaper = {
    enable = mkEnableOption "Hyprpaper";
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
        xdg.configFile = {
          "hypr/hyprpaper.conf".text = ''
            # ░█░█░█▀█░█░░░█░░░█▀█░█▀█░█▀█░█▀▀░█▀▄░█▀▀
            # ░█▄█░█▀█░█░░░█░░░█▀▀░█▀█░█▀▀░█▀▀░█▀▄░▀▀█
            # ░▀░▀░▀░▀░▀▀▀░▀▀▀░▀░░░▀░▀░▀░░░▀▀▀░▀░▀░▀▀▀

            ${concatStringsSep "\n" (map (wallpaper: "preload = ${wallpaper}") cfg.wallpapers)}
            
            ${concatStringsSep "\n" (map (monitor: "wallpaper = ${monitor.name},${monitor.wallpaper}") cfg.monitors)}
            
          '';
        };

        systemd.user.services.hyprpaper = {
          Install.WantedBy = [ "hyprland-session.target" ];

          Unit = {
            Description = "Hyprpaper Service";
            PartOf = [ "graphical-session.target" ];
          };

          Service = {
            ExecStart = "${getExe pkgs.hyprpaper}";
            Restart = "always";
          };
        };
      };
}
