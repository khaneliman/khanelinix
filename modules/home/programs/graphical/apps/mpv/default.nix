{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.khanelinix.programs.graphical.apps.mpv;

in
{
  options.khanelinix.programs.graphical.apps.mpv = {
    enable = lib.mkEnableOption "support for mpv";
  };

  config = mkIf cfg.enable {
    programs.mpv = {
      enable = pkgs.stdenv.hostPlatform.isLinux;
      package = pkgs.mpv;

      defaultProfiles = [ "gpu-hq" ];

      scripts = lib.optionals pkgs.stdenv.hostPlatform.isLinux [
        # Control using media keys
        pkgs.mpvScripts.mpris
        # mpv keyboard shortcuts
        pkgs.mpvScripts.mpv-cheatsheet
        # UI Tweaks
        pkgs.mpvScripts.uosc
      ];
    };

    # FIXME: high cpu usage
    # services.plex-mpv-shim.enable = pkgs.stdenv.hostPlatform.isLinux;
  };
}
