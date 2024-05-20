{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt enabled;

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
        (pulsemixer.overrideAttrs {
          postFixup = ''
            substituteInPlace "$out/bin/pulsemixer" \
              --replace "libpulse.so.0" "$libpulseaudio/lib/libpulse${
                if stdenv.isLinux then ".so.0" else ".0.dylib"
              }"
          '';
        })
      ]
      ++ lib.optionals pkgs.stdenv.isLinux [
        ardour
        mpd-notification
        mpdevil
        spicetify-cli
        tageditor
        youtube-music
        pkgs.khanelinix.yt-music
      ];

    khanelinix = {
      programs.terminal = {
        media = {
          ncmpcpp = enabled;
          ncspot = enabled;
        };

        tools = {
          cava = enabled;
        };
      };

      services = {
        mpd = mkIf pkgs.stdenv.isLinux enabled;
      };
    };
  };
}
