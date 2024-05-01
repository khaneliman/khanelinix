{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt;

  cfg = config.khanelinix.suites.music;
in
{
  options.khanelinix.suites.music = {
    enable = mkBoolOpt false "Whether or not to enable music configuration.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      ardour
      mpd-notification
      mpdevil
      # ncmpcpp
      spicetify-cli
      spotify
      tageditor
      youtube-music
      pkgs.khanelinix.yt-music
    ];

    khanelinix = {
      user.extraGroups = [ "mpd" ];
    };
  };
}
