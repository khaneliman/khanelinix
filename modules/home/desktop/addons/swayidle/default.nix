{ options
, config
, lib
, ...
}:
let
  inherit (lib) types mkIf getExe;
  inherit (lib.internal) mkBoolOpt;

  cfg = config.khanelinix.desktop.addons.swayidle;
in
{
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
          command = "${getExe config.programs.swaylock.package} -df";
        }
        {
          event = "after-resume";
          command = "${config.wayland.windowManager.hyprland.package}/bin/hyprctl dispatch dpms on";
        }
        {
          event = "lock";
          command = "${getExe config.programs.swaylock.package} -df";
        }
      ];
      timeouts = [
        {
          timeout = 300;
          command = "${getExe config.programs.swaylock.package} -df";
        }
        {
          timeout = 600;
          command = "${config.wayland.windowManager.hyprland.package}/bin/hyprctl dispatch dpms off";
        }
      ];
    };
  };
}
