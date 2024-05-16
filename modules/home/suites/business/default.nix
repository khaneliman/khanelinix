{
  config,
  lib,
  pkgs,
  ...
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
    home.packages =
      with pkgs;
      [
        calcurse
        dooit
        jrnl
        np
      ]
      ++ lib.optionals stdenv.isLinux [
        libreoffice
        teams-for-linux
      ]
      ++ lib.optionals stdenv.isDarwin [ teams ];

    khanelinix = {
      programs = {
        graphical = {
          apps = {
            _1password = enabled;
          };
        };
      };
    };
  };
}
