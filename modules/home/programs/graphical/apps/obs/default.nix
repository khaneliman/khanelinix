{
  config,
  lib,
  pkgs,

  ...
}:
let

  cfg = config.khanelinix.programs.graphical.apps.obs;
in
{
  options.khanelinix.programs.graphical.apps.obs = {
    enable = lib.mkEnableOption "support for OBS";
  };

  config = lib.mkIf cfg.enable {
    programs.obs-studio = {
      enable = true;
      package = pkgs.obs-studio;

      plugins =
        with pkgs.obs-studio-plugins;
        [
          obs-gstreamer
          obs-move-transition
          obs-multi-rtmp
          obs-pipewire-audio-capture
          obs-vkcapture
          wlrobs
        ]
        ++ lib.optional config.programs.looking-glass-client.enable looking-glass-obs;
    };
  };
}
