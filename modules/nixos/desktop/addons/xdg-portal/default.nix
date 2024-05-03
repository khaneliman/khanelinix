{
  config,
  inputs,
  lib,
  pkgs,
  system,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt;
  inherit (inputs) hyprland;

  cfg = config.khanelinix.desktop.addons.xdg-portal;
in
{
  options.khanelinix.desktop.addons.xdg-portal = {
    enable = mkBoolOpt false "Whether or not to add support for xdg portal.";
  };

  config = mkIf cfg.enable {
    xdg = {
      portal = {
        enable = true;
        config = {
          common =
            let
              portal =
                if config.khanelinix.desktop.hyprland.enable == "Hyprland" then
                  "hyprland"
                else if config.khanelinix.desktop.sway.enable == "sway" then
                  "wlr"
                else
                  "gtk";
            in
            {
              default = [
                "hyprland"
                "gtk"
              ];

              # for flameshot to work
              # https://github.com/flameshot-org/flameshot/issues/3363#issuecomment-1753771427
              "org.freedesktop.impl.portal.Screencast" = "${portal}";
              "org.freedesktop.impl.portal.Screenshot" = "${portal}";
            };
        };
        extraPortals =
          with pkgs;
          [ xdg-desktop-portal-gtk ]
          ++ (lib.optional config.khanelinix.desktop.sway.enable xdg-desktop-portal-wlr)
          ++ (lib.optional config.khanelinix.desktop.hyprland.enable
            hyprland.packages.${system}.xdg-desktop-portal-hyprland
          );
        # xdgOpenUsePortal = true;
      };
    };
  };
}
