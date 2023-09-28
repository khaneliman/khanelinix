{ config
, lib
, options
, pkgs
, inputs
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt;
  inherit (inputs) ranger-devicons ranger-udisk-menu;

  cfg = config.khanelinix.cli-apps.ranger;
in
{
  options.khanelinix.cli-apps.ranger = {
    enable = mkBoolOpt false "Whether or not to enable ranger.";
  };

  config = mkIf cfg.enable {
    xdg.configFile = {
      "ranger" = {
        source = lib.cleanSourceWith {
          src = lib.cleanSource ./config/.;
        };

        recursive = true;
      };

      "ranger/config/local.conf".text =
        ''''
        + lib.optionalString pkgs.stdenv.isDarwin ''
          # Go to
          map ga cd /Applications
          map gb cd /opt/homebrew
          map gC cd ~/Library/Application Support/
          map gV cd /Volumes

          unmap g?
          unmap gM
          unmap gi
          unmap gm
          unmap gr
        '';

      "ranger/plugins/__init__.py".source = ./config/plugins/__init__.py;
      "ranger/plugins/ranger_devicons".source = ranger-devicons;
      "ranger/plugins/ranger_udisk_menu".source = ranger-udisk-menu;
    };
  };
}
