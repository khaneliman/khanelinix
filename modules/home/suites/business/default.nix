{
  config,
  lib,
  pkgs,
  khanelinix-lib,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (khanelinix-lib) mkBoolOpt enabled;

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
        teams-for-linux
      ]
      ++ lib.optionals stdenv.isLinux [
        libreoffice
        p3x-onenote
      ];

    khanelinix = {
      programs = {
        terminal = {
          tools = {
            _1password-cli = lib.mkDefault enabled;
          };
        };
      };
    };
  };
}
