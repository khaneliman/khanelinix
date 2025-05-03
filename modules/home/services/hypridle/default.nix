{
  config,
  lib,
  namespace,
  osConfig,
  ...
}:
let
  inherit (lib) mkIf getExe getExe';

  cfg = config.${namespace}.services.hypridle;
in
{
  options.${namespace}.services.hypridle = {
    enable = lib.mkEnableOption "hypridle service";
  };

  config = mkIf cfg.enable {
    services.hypridle = {
      enable = true;

      settings = {
        general = {
          after_sleep_cmd = "${getExe' config.wayland.windowManager.hyprland.package "hyprctl"} dispatch dpms on";
          before_sleep_cmd = "loginctl lock-session";
          ignore_dbus_inhibit = false;
          lock_cmd = "pgrep hyprlock || ${getExe config.programs.hyprlock.package}";
        };

        listener = [
          {
            timeout = 300;
            on-timeout = "${getExe config.programs.hyprlock.package}";
          }
          {
            timeout = 600;
            on-timeout = "${getExe' config.wayland.windowManager.hyprland.package "hyprctl"} dispatch dpms off";
            on-resume = "${getExe' config.wayland.windowManager.hyprland.package "hyprctl"} dispatch dpms on";
          }
        ];
      };
    };

    systemd.user.services.hypridle.Install.WantedBy = lib.optionals (
      !osConfig.programs.hyprland.withUWSM
    ) [ "hyprland-session.target" ];
  };
}
