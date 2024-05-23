{
  config,
  inputs,
  lib,
  pkgs,
  system,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  inherit (inputs) hyprland;

  cfg = config.${namespace}.programs.graphical.addons.xdg-portal;
in
{
  options.${namespace}.programs.graphical.addons.xdg-portal = {
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
                if config.${namespace}.programs.graphical.wms.hyprland.enable == "Hyprland" then
                  "hyprland"
                else if config.${namespace}.programs.graphical.wms.sway.enable == "sway" then
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
          ++ (lib.optional config.${namespace}.programs.graphical.wms.sway.enable xdg-desktop-portal-wlr)
          ++ (lib.optional config.${namespace}.programs.graphical.wms.hyprland.enable
            hyprland.packages.${system}.xdg-desktop-portal-hyprland
          );
        # xdgOpenUsePortal = true;
      };
    };
  };
}
