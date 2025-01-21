{
  config,
  khanelinix-lib,
  lib,
  pkgs,
  ...
}:
let
  inherit (khanelinix-lib) mkBoolOpt;

  cfg = config.khanelinix.programs.graphical.apps.obs;
in
{
  options.khanelinix.programs.graphical.apps.obs = {
    enable = mkBoolOpt false "Whether or not to enable support for OBS.";
  };

  config = lib.mkIf cfg.enable {
    programs.obs-studio = {
      enable = true;
      package = pkgs.obs-studio;

      plugins = with pkgs.obs-studio-plugins; [
        looking-glass-obs
        obs-gstreamer
        obs-move-transition
        obs-multi-rtmp
        obs-pipewire-audio-capture
        obs-vkcapture
        wlrobs
      ];
    };
  };
}
