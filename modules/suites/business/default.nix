{ options
, config
, lib
, pkgs
, ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.suites.business;
in
{
  options.khanelinix.suites.business = with types; {
    enable = mkBoolOpt false "Whether or not to enable business configuration.";
  };

  config =
    mkIf cfg.enable {
      khanelinix = {
        apps = {
          thunderbird = enabled;
          teams = enabled;
          libreoffice = enabled;
        };
      };
    };
}
