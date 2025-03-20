{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) enabled;

  cfg = config.${namespace}.suites.business;
in
{
  options.${namespace}.suites.business = {
    enable = lib.mkEnableOption "business configuration";
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
