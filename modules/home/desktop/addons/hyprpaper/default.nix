{ config
, inputs
, lib
, pkgs
, system
, ...
}:
let
  inherit (lib) getExe' getExe mkIf mkEnableOption types mkOption;
  inherit (lib.internal) mkOpt;
  # inherit (inputs) hyprpaper hypr-socket-watch;

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
        services.hyprpaper = {
          enable = true;
          # package = hyprpaper.packages.${system}.hyprpaper;
          package = pkgs.hyprpaper;
          preloads = cfg.wallpapers;
          wallpapers = map (monitor: "${monitor.name},${monitor.wallpaper}") cfg.monitors;
        };

        xdg.configFile = {
          "hypr-socket-watch/config.yaml".text = /*yaml*/ ''
            monitor: "DP-1"
            wallpapers: "${pkgs.khanelinix.wallpapers}/share/wallpapers/"
            debug: true
          '';
        };

        systemd.user.services.hypr-socket-watch = {
          Install.WantedBy = [ "default.target" ];

          Unit = {
            Description = "Hyprland Socket Watch Service";
            BindsTo = [ "graphical-session.target" ];
            After = [ "graphical-session.target" ];
            X-Restart-Triggers = [
              config.xdg.configFile."hypr-socket-watch/config.yaml".source
            ];
          };

          Service = {
            Environment = [
              "PATH=${
              lib.makeBinPath ([config.wayland.windowManager.hyprland.package])
              }"
            ];
            ExecStart = "${getExe pkgs.hypr-socket-watch}";
            Restart = "on-failure";
          };
        };
      };
}
