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

  cfg = config.${namespace}.programs.graphical.apps.mpv;

in
{
  options.${namespace}.programs.graphical.apps.mpv = {
    enable = mkBoolOpt false "Whether or not to enable support for mpv.";
  };

  config = mkIf cfg.enable {
    programs.mpv = {
      enable = pkgs.stdenv.hostPlatform.isLinux;
      package = pkgs.mpv;

      defaultProfiles = [ "gpu-hq" ];
      scripts = lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.mpvScripts.mpris ];
    };

    services.plex-mpv-shim.enable = pkgs.stdenv.hostPlatform.isLinux;
  };
}
