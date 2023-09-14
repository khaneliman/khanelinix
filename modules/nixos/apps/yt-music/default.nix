{ options
, config
, lib
, pkgs
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt;
  cfg = config.khanelinix.apps.yt-music;
in
{
  options.khanelinix.apps.yt-music = {
    enable = mkBoolOpt false "Whether or not to enable YouTube Music.";
  };

  config =
    mkIf cfg.enable { environment.systemPackages = with pkgs.khanelinix; [ yt-music ]; };
}
