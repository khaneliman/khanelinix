{
  config,
  lib,
  pkgs,

  osConfig ? { },
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.khanelinix) enabled;

  cfg = config.khanelinix.suites.business;
  isWSL = osConfig.khanelinix.archetypes.wsl.enable or false;
in
{
  options.khanelinix.suites.business = {
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
      ]
      ++ lib.optionals (!isWSL) [
        teams-for-linux
      ]
      ++ lib.optionals (stdenv.hostPlatform.isLinux && !isWSL) [
        libreoffice
        p3x-onenote
      ];

    khanelinix = {
      programs = {
        graphical = {
          apps = {
            thunderbird.enable = lib.mkDefault (!isWSL); # No GUI email client in WSL
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
        davmail.enable = lib.mkDefault pkgs.stdenv.hostPlatform.isLinux;
        syncthing.enable = lib.mkDefault (!isWSL);
      };
    };
  };
}
