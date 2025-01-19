{
  config,
  khanelinix-lib,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (khanelinix-lib) mkBoolOpt;

  cfg = config.khanelinix.programs.graphical.apps.mpv;

in
{
  options.khanelinix.programs.graphical.apps.mpv = {
    enable = mkBoolOpt false "Whether or not to enable support for mpv.";
  };

  config = mkIf cfg.enable {
    programs.mpv = {
      enable = pkgs.stdenv.isLinux;
      package = pkgs.mpv;

      defaultProfiles = [ "gpu-hq" ];
      scripts = lib.optionals pkgs.stdenv.isLinux [ pkgs.mpvScripts.mpris ];
    };

    services.plex-mpv-shim.enable = pkgs.stdenv.isLinux;
  };
}
