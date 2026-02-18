{
  config,
  lib,
  osConfig ? { },
  ...
}:
let
  cfg = config.khanelinix.services.hypridle;
in
{
  options.khanelinix.services.hypridle = {
    enable = lib.mkEnableOption "hypridle service";
  };

  config = lib.mkIf cfg.enable {
    services.hypridle = {
      enable = true;

      settings = {
        general = {
          after_sleep_cmd = "hyprctl dispatch dpms on";
          before_sleep_cmd = "loginctl lock-session";
          ignore_dbus_inhibit = false;
          lock_cmd = "pidof hyprlock || hyprlock --grace 600";
        };

        listener = [
          {
            timeout = 600;
            on-timeout = "loginctl lock-session";
          }
          {
            timeout = 3600;
            on-timeout = "hyprctl dispatch dpms off";
            on-resume = "hyprctl dispatch dpms on";
          }
        ];
      };
    };

    systemd.user.services.hypridle = {
      Unit.ConditionEnvironment = lib.mkForce "HYPRLAND_INSTANCE_SIGNATURE";
      Install.WantedBy = lib.optionals (!(osConfig.programs.hyprland.withUWSM or false)) [
        "hyprland-session.target"
      ];
    };
  };
}
