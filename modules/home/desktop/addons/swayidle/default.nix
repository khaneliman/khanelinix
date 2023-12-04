{ config
, lib
, options
, ...
}:
let
  inherit (lib) mkIf getExe getExe';
  inherit (lib.internal) mkBoolOpt;

  cfg = config.khanelinix.desktop.addons.swayidle;
in
{
  options.khanelinix.desktop.addons.swayidle = {
    enable =
      mkBoolOpt false "Whether to enable swayidle in the desktop environment.";
  };

  config = mkIf cfg.enable {
    services.swayidle = {
      enable = true;
      events = [
        {
          event = "before-sleep";
          command = "${getExe config.programs.swaylock.package} -defF";
        }
        {
          # TODO: Make dynamic for window manager
          event = "after-resume";
          command = "${getExe' config.wayland.windowManager.hyprland.package "hyprctl"} dispatch dpms on";
        }
        {
          event = "lock";
          command = "${getExe config.programs.swaylock.package} -defF";
        }
      ];
      timeouts = [
        {
          timeout = 900;
          command = "${getExe config.programs.swaylock.package} -defF";
        }
        {
          # TODO: Make dynamic for window manager
          timeout = 1200;
          command = "${getExe' config.wayland.windowManager.hyprland.package "hyprctl"} dispatch dpms off";
        }
      ];
    };
  };
}
