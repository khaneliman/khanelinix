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
    officeEnable = lib.mkEnableOption "office applications";
    pimEnable = lib.mkEnableOption "personal information management applications";
  };

  config = mkIf cfg.enable {
    home.packages =
      with pkgs;
      [
        bitwarden-desktop
        # FIXME: broken nixpkgs
        # jrnl
        np
        slack
      ]
      ++ lib.optionals cfg.pimEnable [
        calcurse
        dooit
      ]
      ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
        meetingbar
      ]
      ++ lib.optionals (stdenv.hostPlatform.isLinux && !isWSL) (
        lib.optionals cfg.officeEnable [
          libreoffice
          p3x-onenote
        ]
      );

    khanelinix = {
      programs = {
        graphical = {
          apps = {
            teams-for-linux.enable = lib.mkDefault (!isWSL);
            thunderbird.enable = lib.mkDefault (!isWSL); # No GUI email client in WSL
          };
        };
        terminal = {
          social = {
            slack-term = lib.mkDefault enabled;
          };
          tools = {
            _1password-cli = lib.mkDefault enabled;
          };
        };
      };
      services = {
        # FIXME: requires approval
        davmail.enable = lib.mkDefault pkgs.stdenv.hostPlatform.isLinux;
        # FIXME: not even being used on darwin and causing network/fs issues
        syncthing.enable = lib.mkDefault (!isWSL && !pkgs.stdenv.hostPlatform.isDarwin);
      };
    };
  };
}
