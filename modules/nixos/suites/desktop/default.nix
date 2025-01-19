{
  config,
  lib,
  khanelinix-lib,
  ...
}:
let
  inherit (khanelinix-lib) mkBoolOpt enabled;

  cfg = config.khanelinix.suites.desktop;
in
{
  options.khanelinix.suites.desktop = {
    enable = mkBoolOpt false "Whether or not to enable common desktop configuration.";
  };

  config = lib.mkIf cfg.enable {
    khanelinix = {
      programs = {
        graphical = {
          addons = {
            keyring = lib.mkDefault enabled;
            xdg-portal = lib.mkDefault enabled;
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
