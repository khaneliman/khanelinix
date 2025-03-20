{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
let
  inherit (lib) getExe getExe';

  cfg = config.${namespace}.services.swayidle;
in
{
  options.${namespace}.services.swayidle = {
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
          command = "${getExe config.programs.swaylock.package} -defF";
        }
        {
          event = "after-resume";
          command = ''${getExe' config.wayland.windowManager.sway.package "swaymsg"} "output * dpms on"'';
        }
        {
          event = "lock";
          command = "${getExe config.programs.swaylock.package} -defF";
        }
      ];
      timeouts = [
        {
          timeout = 300;
          command = "${getExe config.programs.swaylock.package} -defF";
        }
        {
          timeout = 600;
          command = ''${getExe' config.wayland.windowManager.sway.package "swaymsg"} "output * dpms off"'';
        }
      ];
    };
  };
}
