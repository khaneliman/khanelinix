{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.${namespace}.display-managers.lightdm;
in
{
  options.${namespace}.display-managers.lightdm = {
    enable = lib.mkEnableOption "lightdm";
  };

  config = mkIf cfg.enable {
    services.xserver = {
      enable = true;

      displayManager.lightdm = {
        enable = true;
        background = pkgs.${namespace}.wallpapers.flatppuccin_macchiato;

        greeters = {
          gtk = {
            enable = true;

            cursorTheme = {
              inherit (config.${namespace}.desktop.addons.gtk.cursor) name;
              package = config.${namespace}.desktop.addons.gtk.cursor.pkg;
            };

            iconTheme = {
              inherit (config.${namespace}.desktop.addons.gtk.icon) name;
              package = config.${namespace}.desktop.addons.gtk.icon.pkg;
            };

            theme = {
              name = "${config.${namespace}.desktop.addons.gtk.theme.name}";
              package = config.${namespace}.desktop.addons.gtk.theme.pkg;
            };
          };
        };
      };
    };

    security.pam.services.greetd = {
      enableGnomeKeyring = true;
      gnupg.enable = true;
    };
  };
}
