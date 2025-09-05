{
  config,
  lib,
  pkgs,
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

      systemdTarget = "sway-session.target";

      events = [
        {
          event = "before-sleep";
          command = "swaylock -defF";
        }
        {
          event = "after-resume";
          command = ''swaymsg "output * dpms on"'';
        }
        {
          event = "lock";
          command = "swaylock -defF";
        }
      ];
      timeouts = [
        {
          timeout = 300;
          command = "swaylock -defF";
        }
        {
          timeout = 600;
          command = ''swaymsg "output * dpms off"'';
        }
      ];
    };
  };
}
