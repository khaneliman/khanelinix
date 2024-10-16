{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.programs.graphical.apps.obs;
in
{
  options.${namespace}.programs.graphical.apps.obs = {
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
        # FIXME: broken nixpkgs
        # obs-multi-rtmp
        obs-pipewire-audio-capture
        # FIXME: broken nixpkgs
        # obs-vkcapture
        wlrobs
      ];
    };
  };
}
