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

  cfg = config.${namespace}.programs.terminal.media.mpv;

in
{
  options.${namespace}.programs.terminal.media.mpv = {
    enable = mkBoolOpt false "Whether or not to enable support for mpv.";
  };

  config = mkIf cfg.enable {
    programs.mpv = {
      enable = true;

      defaultProfiles = [ "gpu-hq" ];
      scripts = lib.optionals pkgs.stdenv.isLinux [ pkgs.mpvScripts.mpris ];
    };

    services.plex-mpv-shim.enable = pkgs.stdenv.isLinux;
  };
}
