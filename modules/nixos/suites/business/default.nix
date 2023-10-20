{ config
, lib
, options
, pkgs
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt enabled;

  cfg = config.khanelinix.suites.business;
in
{
  options.khanelinix.suites.business = {
    enable = mkBoolOpt false "Whether or not to enable business configuration.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      dooit
      libreoffice
    ];

    khanelinix = {
      apps = {
        thunderbird = enabled;
      };
    };
  };
}
