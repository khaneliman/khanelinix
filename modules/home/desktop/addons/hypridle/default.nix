{
  config,
  inputs,
  lib,
  system,
  ...
}:
let
  inherit (lib) mkIf getExe getExe';
  inherit (lib.internal) mkBoolOpt;
  inherit (inputs) hypridle;

  cfg = config.khanelinix.desktop.addons.hypridle;
in
{
  options.khanelinix.desktop.addons.hypridle = {
    enable = mkBoolOpt false "Whether to enable hypridle in the desktop environment.";
  };

  config = mkIf cfg.enable {
    services.hypridle = {
      enable = true;
      package = hypridle.packages.${system}.hypridle;

      settings = {
        general = {
          after_sleep_cmd = "${getExe' config.wayland.windowManager.hyprland.package "hyprctl"} dispatch dpms on";
          ignore_dbus_inhibit = false;
          lock_cmd = "${getExe config.programs.hyprlock.package}";
        };

        listener = [
          {
            timeout = 900;
            on-timeout = "${getExe config.programs.hyprlock.package}";
          }
          {
            timeout = 1200;
            on-timeout = "${getExe' config.wayland.windowManager.hyprland.package "hyprctl"} dispatch dpms off";
            on-resume = "${getExe' config.wayland.windowManager.hyprland.package "hyprctl"} dispatch dpms on";
          }
        ];
      };
    };
  };
}
