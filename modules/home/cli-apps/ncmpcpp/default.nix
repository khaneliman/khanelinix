{ config, lib, ... }:
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
      mpdMusicDir = mkIf config.khanelinix.services.mpd.enable config.khanelinix.services.mpd.musicDirectory;
    };
  };
}
