{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.programs.graphical.addons.xdg-portal;
in
{
  options.${namespace}.programs.graphical.addons.xdg-portal = {
    enable = mkBoolOpt false "Whether or not to add support for xdg portal.";
    enableDebug = mkEnableOption "Enable debug mode.";
  };

  config = mkIf cfg.enable {
    xdg = {
      portal = {
        enable = true;

        configPackages = lib.optionals config.${namespace}.programs.graphical.wms.hyprland.enable [
          pkgs.hyprland
        ];

        config = {
          hyprland = mkIf config.${namespace}.programs.graphical.wms.hyprland.enable {
            default = [
              "hyprland"
              "gtk"
            ];
            "org.freedesktop.impl.portal.Screencast" = "hyprland";
            "org.freedesktop.impl.portal.Screenshot" = "hyprland";
          };

          sway = mkIf config.${namespace}.programs.graphical.wms.sway.enable {
            default = lib.mkDefault [
              "wlr"
              "gtk"
            ];
          };

          common = {
            default = [ "gtk" ];

            "org.freedesktop.impl.portal.Screencast" = "gtk";
            "org.freedesktop.impl.portal.Screenshot" = "gtk";
            "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
          };
        };

        extraPortals = with pkgs; [
          xdg-desktop-portal-gtk
        ];

        wlr = {
          inherit (config.${namespace}.programs.graphical.wms.sway) enable;

          settings = {
            screencast = {
              max_fps = 30;
              chooser_type = "simple";
              chooser_cmd = "${lib.getExe pkgs.slurp} -f %o -or";
            };
          };
        };
      };
    };
  };
}
