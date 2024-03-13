{ config
, lib
, ...
}:
let
  inherit (lib) mkEnableOption mkIf mkOption types;

  cfg = config.khanelinix.services.mpd;
in
{
  options.khanelinix.services.mpd = {
    enable = mkEnableOption "mpd";
    musicDirectory = mkOption {
      type = with types; either path str;
      default = config.xdg.userDirs.music;
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
    services = {
      mpd = {
        enable = true;
        inherit (cfg) musicDirectory;
      };
      mpd-mpris = {
        enable = true;
      };
    };
  };
}
