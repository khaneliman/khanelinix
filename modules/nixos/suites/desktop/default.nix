{
  config,
  lib,

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
    khanelinix = {
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
        flatpak = lib.mkDefault enabled;
      };
    };
  };
}
