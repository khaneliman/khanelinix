{
  config,
  lib,
  pkgs,

  osConfig ? { },
  ...
}:
let
  cfg = config.khanelinix.services.swayidle;
in
{
  options.khanelinix.services.swayidle = {
    enable = lib.mkEnableOption "swayidle service";
  };

  config = lib.mkIf cfg.enable {
    services.swayidle = {
      enable = true;
      package = pkgs.swayidle;

      systemdTarget = lib.mkIf (!(osConfig.programs.uwsm.enable or false)) "sway-session.target";

      events = [
        {
          event = "before-sleep";
          command = "loginctl lock-session";
        }
        {
          event = "after-resume";
          command = ''swaymsg "output * dpms on"'';
        }
        {
          event = "lock";
          command = "pidof swaylock || swaylock -defF";
        }
      ];
      timeouts = [
        {
          timeout = 600;
          command = "loginctl lock-session";
        }
        {
          timeout = 3600;
          command = ''swaymsg "output * dpms off"'';
        }
      ];
    };
  };
}
