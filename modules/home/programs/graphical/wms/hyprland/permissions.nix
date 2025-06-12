{
  config,
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
        permission =
          [
            "${lib.getExe pkgs.grimblast}, screencopy, allow"
            "${lib.getExe pkgs.grim}, screencopy, allow"
            "${lib.getExe pkgs.hyprpicker}, screencopy, allow"
            "${lib.getExe pkgs.${namespace}.record_screen}, screencopy, allow"
            "${config.wayland.windowManager.hyprland.portalPackage}/libexec/.xdg-desktop-portal-hyprland-wrapped, screencopy, allow"
            "${lib.getExe config.programs.hyprlock.package}, screencopy, allow"
          ]
          ++ lib.optional (lib.elem pkgs.hyprlandPlugins.hyprbars config.wayland.windowManager.hyprland.plugins) "${lib.getLib pkgs.hyprlandPlugins.hyprbars}/lib/libhyprbars.so, plugin, allow"
          ++ lib.optional (lib.elem pkgs.hyprlandPlugins.hyprexpo config.wayland.windowManager.hyprland.plugins) "${lib.getLib pkgs.hyprlandPlugins.hyprexpo}/lib/libhyprexpo.so, plugin, allow";
      };
    };
  };
}
