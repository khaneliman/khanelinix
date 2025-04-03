{
  config,
  lib,
  namespace,
  osConfig,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;

  cfg = config.${namespace}.services.cliphist;
in
{
  options.${namespace}.services.cliphist = {
    enable = mkEnableOption "cliphist";

    systemdTargets = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = ''
        Systemd targets for cliphist
      '';
    };
  };

  config = mkIf cfg.enable {
    services = {
      cliphist = {
        enable = true;
        allowImages = true;
        systemdTargets =
          cfg.systemdTargets
          ++
            lib.optionals (config.wayland.windowManager.hyprland.enable && !osConfig.programs.hyprland.withUWSM)
              [
                "hyprland-session.target"
              ]
          ++ lib.optionals config.wayland.windowManager.sway.enable [ "sway-session.target" ];

      };
    };
  };
}
