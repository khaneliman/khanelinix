{
  config,
  lib,
  pkgs,
  namespace,
  osConfig,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) enabled;

  cfg = config.${namespace}.suites.business;
  isWSL = (osConfig.${namespace}.archetypes ? wsl) && osConfig.${namespace}.archetypes.wsl.enable;
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
        jrnl
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
        # davmail.enable = lib.mkDefault pkgs.stdenv.hostPlatform.isLinux;
        syncthing.enable = lib.mkDefault (!isWSL);
      };
    };
  };
}
