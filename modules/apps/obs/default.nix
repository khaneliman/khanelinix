{
  options,
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.apps.obs;
in {
  options.khanelinix.apps.obs = with types; {
    enable = mkBoolOpt false "Whether or not to enable support for OBS.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      (pkgs.wrapOBS {
        plugins = with pkgs.obs-studio-plugins; [
          wlrobs
          obs-multi-rtmp
          obs-move-transition
          looking-glass-obs
        ];
      })
    ];
  };
}
