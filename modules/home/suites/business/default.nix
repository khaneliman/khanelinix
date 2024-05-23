{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt enabled;

  cfg = config.${namespace}.suites.business;
in
{
  options.${namespace}.suites.business = {
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
