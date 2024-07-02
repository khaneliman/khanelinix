{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf getExe getExe';
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.services.swayidle;
in
{
  options.${namespace}.services.swayidle = {
    enable = mkBoolOpt false "Whether to enable swayidle service.";
  };

  config = mkIf cfg.enable {
    services.swayidle = {
      enable = true;
      package = pkgs.swayidle;

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
