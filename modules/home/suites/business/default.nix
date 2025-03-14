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
        # FIXME: broken nixpkg dependency again
        # dooit
        jrnl
        np
        teams-for-linux
      ]
      ++ lib.optionals stdenv.hostPlatform.isLinux [
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
      services = {
        syncthing = lib.mkDefault enabled;
      };
    };
  };
}
