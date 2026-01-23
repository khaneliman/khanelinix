{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.khanelinix.display-managers.lightdm;
in
{
  options.khanelinix.display-managers.lightdm = {
    enable = lib.mkEnableOption "lightdm";
  };

  config = mkIf cfg.enable {
    services.xserver = {
      enable = true;

      displayManager.lightdm = {
        enable = true;
        background = lib.khanelinix.theme.wallpaperPath {
          inherit config pkgs;
          name = config.khanelinix.theme.wallpaper.primary;
        };

        greeters = {
          gtk = {
            enable = true;

            cursorTheme = {
              inherit (config.khanelinix.desktop.addons.gtk.cursor) name;
              package = config.khanelinix.desktop.addons.gtk.cursor.pkg;
            };

            iconTheme = {
              inherit (config.khanelinix.desktop.addons.gtk.icon) name;
              package = config.khanelinix.desktop.addons.gtk.icon.pkg;
            };

            theme = {
              name = "${config.khanelinix.desktop.addons.gtk.theme.name}";
              package = config.khanelinix.desktop.addons.gtk.theme.pkg;
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
