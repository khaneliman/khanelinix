{
  options,
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.desktop.addons.xdg-portal;
in {
  options.khanelinix.desktop.addons.xdg-portal = with types; {
    enable = mkBoolOpt false "Whether or not to add support for xdg portal.";
  };

  config = mkIf cfg.enable {
    xdg = {
      portal = {
        enable = true;
        extraPortals = with pkgs;
          [
            xdg-desktop-portal-gtk
          ]
          ++ (lib.optional config.khanelinix.desktop.hyprland.enable xdg-desktop-portal-hyprland)
          ++ (lib.optional config.khanelinix.desktop.sway.enable xdg-desktop-portal-wlr);
      };
    };
  };
}
