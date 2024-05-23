{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.programs.graphical.apps.obs;
in
{
  options.${namespace}.programs.graphical.apps.obs = {
    enable = mkBoolOpt false "Whether or not to enable support for OBS.";
  };

  config = mkIf cfg.enable {
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
