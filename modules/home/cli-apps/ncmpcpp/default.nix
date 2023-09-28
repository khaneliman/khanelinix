{ config
, lib
, ...
}:
let
  inherit (lib) mkEnableOption mkIf;

  cfg = config.khanelinix.cli-apps.ncmpcpp;
in
{
  options.khanelinix.cli-apps.ncmpcpp = {
    enable = mkEnableOption "ncmpcpp";
  };

  config = mkIf cfg.enable {
    programs.ncmpcpp = {
      enable = true;
      mpdMusicDir = config.khanelinix.services.mpd.musicDirectory;
    };
  };
}
