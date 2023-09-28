{ config
, lib
, options
, pkgs
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt;

  cfg = config.khanelinix.display-managers.lightdm;
in
{
  options.khanelinix.display-managers.lightdm = {
    enable = mkBoolOpt false "Whether or not to enable lightdm.";
  };

  config =
    mkIf cfg.enable
      {
        services.xserver = {
          enable = true;

          displayManager.lightdm = {
            enable = true;
            background = pkgs.khanelinix.wallpapers.flatppuccin_macchiato;

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
