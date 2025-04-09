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

  cfg = config.${namespace}.suites.music;
in
{
  options.${namespace}.suites.music = {
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
        mpdevil
        tageditor
        youtube-music
      ];

    khanelinix = {
      programs.terminal = {
        media = {
          ncmpcpp = lib.mkDefault enabled;
          ncspot = lib.mkDefault enabled;
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
