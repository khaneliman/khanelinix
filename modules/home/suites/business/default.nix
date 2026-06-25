{
  config,
  lib,
  pkgs,

  osConfig ? { },
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.khanelinix)
    enabled
    mkPackageProfileOption
    suiteProfileIncludes
    ;

  cfg = config.khanelinix.suites.business;
  includes = suiteProfileIncludes config cfg;
  isWSL = osConfig.khanelinix.archetypes.wsl.enable or false;
in
{
  options.khanelinix.suites.business = {
    enable = lib.mkEnableOption "business configuration";
    packageProfile = mkPackageProfileOption "Package profile override for business applications.";
    officeEnable = lib.mkEnableOption "office applications";
    pimEnable = lib.mkEnableOption "personal information management applications";
  };

  config = mkIf cfg.enable {
    home.packages =
      with pkgs;
      [
        # FIXME: broken nixpkgs
        # bitwarden-desktop
        jrnl
        np
      ]
      ++ lib.optionals (includes "maximal") [
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
            teams-for-linux.enable = lib.mkDefault (!isWSL && includes "standard");
            thunderbird.enable = lib.mkDefault (!isWSL && includes "standard"); # No GUI email client in WSL
          };
        };
        terminal = {
          social = {
            slack-term.enable = lib.mkDefault (includes "maximal");
          };
          tools = {
            _1password-cli = lib.mkDefault enabled;
            khal.enable = lib.mkDefault cfg.pimEnable;
          };
        };
      };
      services = {
        # FIXME: requires approval
        davmail.enable = lib.mkDefault pkgs.stdenv.hostPlatform.isLinux;
        vdirsyncer.enable = lib.mkDefault (cfg.pimEnable && pkgs.stdenv.hostPlatform.isLinux && !isWSL);
        # FIXME: not even being used on darwin and causing network/fs issues
        # TODO: Don't use yet, at all should take advantage of
        # syncthing.enable = lib.mkDefault (!isWSL && !pkgs.stdenv.hostPlatform.isDarwin);
      };
    };
  };
}
