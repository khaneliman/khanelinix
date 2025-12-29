{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.khanelinix) enabled;

  cfg = config.khanelinix.suites.music;
in
{
  options.khanelinix.suites.music = {
    enable = lib.mkEnableOption "common music configuration";
  };

  config = mkIf cfg.enable {
    home.packages =
      with pkgs;
      [
        musikcube
        pulsemixer
      ]
      ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [
        ardour
        mpd-notification
        plattenalbum
        plexamp
        tageditor
        pear-desktop
      ];

    khanelinix = {
      programs.terminal = {
        media = {
          ncmpcpp = lib.mkDefault enabled;
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
