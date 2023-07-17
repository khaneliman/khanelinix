{
  options,
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.desktop.addons.swayidle;
in {
  options.khanelinix.desktop.addons.swayidle = with types; {
    enable =
      mkBoolOpt false "Whether to enable swayidle in the desktop environment.";
  };

  config = mkIf cfg.enable {
    # screen idle
    services.swayidle = {
      enable = true;
      systemdTarget = "graphical-session.target";
      events = [
        {
          event = "before-sleep";
          command = "swaylock -f -c 000000";
        }
        {
          event = "after-resume";
          command = "hyprctl dispatch dpms on";
        }
        {
          event = "lock";
          command = "${pkgs.swaylock-effects}/bin/swaylock -f";
        }
      ];
      timeouts = [
        {
          timeout = 300;
          command = "swaylock -f";
        }
        {
          timeout = 600;
          command = "hyprctl dispatch dpms off";
        }
      ];
    };
  };
}
