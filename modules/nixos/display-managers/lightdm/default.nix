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
        # LightDM documentation
        # See: https://github.com/canonical/lightdm
        enable = true;
        background = lib.khanelinix.theme.wallpaperPath {
          inherit config pkgs;
          name = config.khanelinix.theme.wallpaper.primary;
        };

        greeters = {
          gtk = {
            enable = true;

            cursorTheme = {
              inherit (config.khanelinix.theme.cursor) name package;
            };

            iconTheme = {
              inherit (config.khanelinix.theme.icon) name package;
            };

            theme = {
              inherit (config.khanelinix.theme.gtk.theme) name package;
            };
          };
        };
      };
    };

    security.pam.services.lightdm = {
      enableGnomeKeyring = true;
      gnupg.enable = true;
    };
  };
}
