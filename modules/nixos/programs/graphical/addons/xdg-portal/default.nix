{
  config,
  inputs,
  lib,
  pkgs,
  khanelinix-lib,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (khanelinix-lib) mkBoolOpt;
  inherit (inputs) hyprland;

  cfg = config.khanelinix.programs.graphical.addons.xdg-portal;
in
{
  options.khanelinix.programs.graphical.addons.xdg-portal = {
    enable = mkBoolOpt false "Whether or not to add support for xdg portal.";
  };

  config = mkIf cfg.enable {
    xdg = {
      portal = {
        enable = true;

        configPackages = lib.optionals config.khanelinix.programs.graphical.wms.hyprland.enable [
          hyprland.packages.${pkgs.stdenv.system}.hyprland
        ];

        config = {
          hyprland = mkIf config.khanelinix.programs.graphical.wms.hyprland.enable {
            default = [
              "hyprland"
              "gtk"
            ];
            "org.freedesktop.impl.portal.Screencast" = "hyprland";
            "org.freedesktop.impl.portal.Screenshot" = "hyprland";
          };

          sway = mkIf config.khanelinix.programs.graphical.wms.sway.enable {
            default = lib.mkDefault [
              "wlr"
              "gtk"
            ];
            "org.freedesktop.impl.portal.Screencast" = "wlr";
            "org.freedesktop.impl.portal.Screenshot" = "wlr";
          };

          common = {
            default = [ "gtk" ];

            "org.freedesktop.impl.portal.Screencast" = "gtk";
            "org.freedesktop.impl.portal.Screenshot" = "gtk";
            "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
          };
        };

        extraPortals =
          with pkgs;
          [ xdg-desktop-portal-gtk ]
          ++ (lib.optional config.khanelinix.programs.graphical.wms.sway.enable xdg-desktop-portal-wlr)
          ++ (lib.optional config.khanelinix.programs.graphical.wms.hyprland.enable (
            hyprland.packages.${system}.xdg-desktop-portal-hyprland.override {
              debug = true;
              # TODO: use same package as home-manager
              inherit (hyprland.packages.${system}) hyprland;
            }
          ));
        # xdgOpenUsePortal = true;

        wlr = {
          inherit (config.khanelinix.programs.graphical.wms.sway) enable;

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
