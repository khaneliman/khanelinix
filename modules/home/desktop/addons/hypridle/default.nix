{ config
, inputs
, lib
, options
, pkgs
, system
, ...
}:
let
  inherit (lib) mkIf getExe getExe';
  inherit (lib.internal) mkBoolOpt;
  # inherit (inputs) hypridle;

  cfg = config.khanelinix.desktop.addons.hypridle;
in
{
  options.khanelinix.desktop.addons.hypridle = {
    enable =
      mkBoolOpt false "Whether to enable hypridle in the desktop environment.";
  };

  config = mkIf cfg.enable {
    services.hypridle = {
      enable = true;
      # package = hypridle.packages.${system}.hypridle;
      package = pkgs.hypridle;

      lockCmd = "${getExe config.programs.hyprlock.package}";
      afterSleepCmd = "${getExe' config.wayland.windowManager.hyprland.package "hyprctl"} dispatch dpms on";

      listeners = [
        {
          timeout = 900;
          onTimeout = "${getExe config.programs.hyprlock.package}";
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
