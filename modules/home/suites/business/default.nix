{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) mkIf;
  inherit (flake.inputs.self.lib.khanelinix) mkBoolOpt enabled;

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
