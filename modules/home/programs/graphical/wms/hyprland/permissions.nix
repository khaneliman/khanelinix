{
  config,
  inputs,
  lib,
  namespace,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.${namespace}.programs.graphical.wms.hyprland;
in
{
  config = mkIf cfg.enable {
    wayland.windowManager.hyprland = {
      settings = {
        permission = [
          "${lib.getExe pkgs.grimblast}, screencopy, allow"
          "${lib.getExe pkgs.grim}, screencopy, allow"
          "${lib.getExe pkgs.hyprpicker}, screencopy, allow"
          "${lib.getExe pkgs.${namespace}.record_screen}, screencopy, allow"
          "${config.wayland.windowManager.hyprland.portalPackage}/libexec/.xdg-desktop-portal-hyprland-wrapped, screencopy, allow"
          "${lib.getExe config.programs.hyprlock.package}, screencopy, allow"
          "${
            lib.getLib inputs.hyprland-plugins.packages.${pkgs.system}.hyprbars
          }/lib/libhyprbars.so, plugin, allow"
          "${
            lib.getLib inputs.hyprland-plugins.packages.${pkgs.system}.hyprexpo
          }/lib/libhyprexpo.so, plugin, allow"
        ];
      };
    };
  };
}
