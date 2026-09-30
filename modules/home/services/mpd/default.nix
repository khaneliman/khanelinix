{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;

  cfg = config.khanelinix.services.mpd;
in
{
  options.khanelinix.services.mpd = {
    enable = mkEnableOption "mpd";
    musicDirectory = mkOption {
      type = with types; either path str;
      default = config.xdg.userDirs.music;
      defaultText = lib.literalExpression "config.xdg.userDirs.music";
      apply = toString; # Prevent copies to Nix store.
      description = ''
        The directory where mpd reads music from.

        If [](#opt-xdg.userDirs.enable) is
        `true` then the defined XDG music directory is used.
        Otherwise, you must explicitly specify a value.
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion =
          !(
            config.services.mpdris2.enable
            && config.services.mpd-mpris.enable
            && config.services.mpd-mpris.settings.instance-name == null
          );
        message = "services.mpdris2 and services.mpd-mpris both own org.mpris.MediaPlayer2.mpd; enable only one bridge.";
      }
    ];

    home.packages =
      with pkgs;
      [
        playerctl # CLI interface for playerctld
        mpc # CLI interface for mpd
      ]
      ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [
        cava # CLI music visualizer (cavalier is a gui alternative)
        mpd-notification
      ];

    services = {
      mpd = {
        # MPD documentation
        # See: https://www.musicpd.org/doc/html/
        enable = true;
        inherit (cfg) musicDirectory;

        network = {
          startWhenNeeded = true;
          listenAddress = "127.0.0.1";
          port = 6600;
        };

        extraConfig = ''
          auto_update           "yes"
          volume_normalization  "yes"
          restore_paused        "yes"
          filesystem_charset    "UTF-8"

          audio_output {
            type                "pipewire"
            name                "PipeWire"
          }

          audio_output {
            type                "fifo"
            name                "Visualiser"
            path                "/tmp/mpd.fifo"
            format              "44100:16:2"
          }

          audio_output {
           type		              "httpd"
           name		              "lossless"
           encoder		          "flac"
           port		              "8000"
           max_clients	        "8"
           mixer_type	          "software"
           format		            "44100:16:2"
          }
        '';
      };

      mpris-proxy.enable = true;
      # TODO: move to nixos service?
      # playerctld.enable = true;

      # Only one MPD bridge can own org.mpris.MediaPlayer2.mpd.
      mpdris2 = {
        enable = lib.mkDefault (!config.services.mpd-mpris.enable);
        settings = {
          Bling = {
            notify = true;
            mmkeys = true;
          };
          Library.music_dir = null;
        };
      };

      # discord rich presence for mpd
      mpd-discord-rpc = {
        enable = false;

        settings = {
          format = {
            details = "$title";
            state = "On $album by $artist";
            large_text = "$album";
            small_image = "";
          };
        };
      };
    };
  };
}
