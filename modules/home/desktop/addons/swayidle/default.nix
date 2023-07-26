{
  options,
  config,
  lib,
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
    services.swayidle = {
      enable = true;
      systemdTarget = "graphical-session.target";
      # TODO: Make dynamic for window manager
      events = [
        {
          event = "before-sleep";
          command = "${config.programs.swaylock.package}/bin/swaylock -f -c 000000";
        }
        {
          event = "after-resume";
          command = "${config.wayland.windowManager.hyprland.package}/bin/hyprctl dispatch dpms on";
        }
        {
          event = "lock";
          command = "${config.programs.swaylock.package}/bin/swaylock -f";
        }
      ];
      timeouts = [
        {
          timeout = 300;
          command = "${config.programs.swaylock.package}/bin/swaylock -f";
        }
        {
          timeout = 600;
          command = "${config.wayland.windowManager.hyprland.package}/bin/hyprctl dispatch dpms off";
        }
      ];
    };
  };
}
