{
  config,
  lib,

  osConfig ? { },
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;

  cfg = config.khanelinix.services.wl-clip-persist;
in
{
  options.khanelinix.services.wl-clip-persist = {
    enable = mkEnableOption "wl-clip-persist";

    systemdTargets = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = ''
        Systemd targets for wl-clip-persist
      '';
    };
  };

  config = mkIf cfg.enable {
    services = {
      wl-clip-persist = {
        enable = true;
        clipboardType = "both";
        systemdTargets =
          cfg.systemdTargets
          ++ lib.optionals (
            (config.wayland.windowManager.hyprland.enable && (osConfig.programs.hyprland.withUWSM or false))
            || (config.wayland.windowManager.sway.enable && (osConfig.programs.uwsm.enable or false))
          ) [ "graphical-session.target" ]
          ++
            lib.optionals
              (config.wayland.windowManager.hyprland.enable && !(osConfig.programs.hyprland.withUWSM or false))
              [
                "hyprland-session.target"
              ]
          ++ lib.optionals (
            config.wayland.windowManager.sway.enable && !(osConfig.programs.uwsm.enable or false)
          ) [ "sway-session.target" ];

      };
    };

    systemd.user.services.wl-clip-persist.Unit.ConditionEnvironment = "WAYLAND_DISPLAY";
  };
}
