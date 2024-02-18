{ config
, inputs
, lib
, options
, pkgs
, ...
}:
let
  inherit (lib) mkIf getExe getExe';
  inherit (lib.internal) mkBoolOpt;
  inherit (inputs) hypridle;

  cfg = config.khanelinix.desktop.addons.hypridle;
in
{
  imports = [ hypridle.homeManagerModules.default ];

  options.khanelinix.desktop.addons.hypridle = {
    enable =
      mkBoolOpt false "Whether to enable hypridle in the desktop environment.";
  };

  config = mkIf cfg.enable {
    services.hypridle = {
      enable = true;
      package = pkgs.hypridle;

      lockCmd = "${getExe config.programs.swaylock.package} -defF";
      afterSleepCmd = "${getExe' config.wayland.windowManager.hyprland.package "hyprctl"} dispatch dpms on";

      listeners = [
        {
          timeout = 900;
          onTimeout = "${getExe config.programs.swaylock.package} -defF";
        }
        {
          timeout = 1200;
          onTimeout = "${getExe' config.wayland.windowManager.hyprland.package "hyprctl"} dispatch dpms off";
          onResume = "${getExe' config.wayland.windowManager.hyprland.package "hyprctl"} dispatch dpms on";
        }
      ];
    };
  };
}
