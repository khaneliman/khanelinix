{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.khanelinix) enabled mkPackageProfileOption;

  cfg = config.khanelinix.suites.music;
in
{
  options.khanelinix.suites.music = {
    enable = lib.mkEnableOption "common music configuration";
    packageProfile = mkPackageProfileOption "Package profile override for music applications.";
    productionEnable = lib.mkEnableOption "audio production applications";
    managementEnable = lib.mkEnableOption "audio management applications";
  };

  config = mkIf cfg.enable {
    home.packages =
      with pkgs;
      [
        musikcube
        pulsemixer
      ]
      ++ lib.optionals cfg.managementEnable [
        pear-desktop
        # FIXME: broken dependency
        # tageditor
      ]
      ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux (
        [
          plexamp
        ]
        ++ lib.optionals cfg.productionEnable [
          ardour
        ]
        ++ lib.optionals cfg.managementEnable [
          plattenalbum
        ]
      );

    khanelinix = {
      programs.terminal = {
        media = {
          ncmpcpp = mkIf pkgs.stdenv.hostPlatform.isLinux (lib.mkDefault enabled);
          ncspot = lib.mkDefault enabled;
          rmpc = mkIf pkgs.stdenv.hostPlatform.isLinux (lib.mkDefault enabled);
        };

        tools = {
          cava = lib.mkDefault enabled;
        };
      };

      services = {
        mpd = mkIf pkgs.stdenv.hostPlatform.isLinux enabled;
      };
    };
  };
}
