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
        dooit
        # FIXME: broken nixpkgs
        # jrnl
        np
        teams-for-linux
      ]
      ++ lib.optionals stdenv.hostPlatform.isLinux [
        libreoffice
        p3x-onenote
      ];

    khanelinix = {
      programs = {
        graphical = {
          apps = {
            thunderbird = lib.mkDefault enabled;
          };
        };
        terminal = {
          tools = {
            _1password-cli = lib.mkDefault enabled;
          };
        };
      };
      services = {
        # FIXME: requires approval
        # davmail.enable = lib.mkDefault pkgs.stdenv.hostPlatform.isLinux;
        syncthing = lib.mkDefault enabled;
      };
    };
  };
}
