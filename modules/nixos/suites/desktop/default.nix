{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib.khanelinix) enabled;

  cfg = config.khanelinix.suites.desktop;
in
{
  options.khanelinix.suites.desktop = {
    enable = lib.mkEnableOption "common desktop configuration";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      usbimager
      xclip
    ];

    khanelinix = {
      hardware = {
        power = lib.mkDefault enabled;
        fans = lib.mkDefault enabled;
      };

      programs = {
        graphical = {
          addons = {
            keyring = lib.mkDefault enabled;
          };

          apps = {
            _1password = lib.mkDefault enabled;
          };
        };
      };

      services = {
        ddc = lib.mkDefault enabled;
        flatpak = lib.mkDefault enabled;
        lact = lib.mkDefault enabled;
        printing = lib.mkDefault enabled;
      };
    };
  };
}
