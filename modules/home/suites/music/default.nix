{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.khanelinix) mkBoolOpt enabled;

  cfg = config.khanelinix.suites.music;
in
{
  options.khanelinix.suites.music = {
    enable = mkBoolOpt false "Whether or not to enable common music configuration.";
  };

  config = mkIf cfg.enable {
    home.packages =
      with pkgs;
      [
        musikcube
        pulsemixer
      ]
      ++ lib.optionals pkgs.stdenv.isLinux [
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
        mpd = mkIf pkgs.stdenv.isLinux enabled;
      };
    };
  };
}
