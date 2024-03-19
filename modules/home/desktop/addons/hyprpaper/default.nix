{ config
, inputs
, lib
, system
, ...
}:
let
  inherit (lib) mkIf mkEnableOption types mkOption;
  inherit (lib.internal) mkOpt;
  inherit (inputs) hyprpaper;

  cfg = config.khanelinix.desktop.addons.hyprpaper;
in
{
  imports = [ hyprpaper.homeManagerModules.default ];

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
          package = hyprpaper.packages.${system}.hyprpaper;
          preloads = cfg.wallpapers;
          wallpapers = map (monitor: "${monitor.name},${monitor.wallpaper}") cfg.monitors;
        };

        # FIX: broken with recent hyprpaper/hyprland updates... need to fix
        # systemd.user.services.hypr_socket_watch = {
        #   Install.WantedBy = [ "hyprland-session.target" ];
        #
        #   Unit = {
        #     Description = "Hypr Socket Watch Service";
        #     PartOf = [ "graphical-session.target" ];
        #   };
        #
        #   Service = {
        #     ExecStart = "${getExe pkgs.khanelinix.hypr_socket_watch}";
        #     Restart = "on-failure";
        #   };
        # };
      };
}
