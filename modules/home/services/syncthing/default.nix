{
  config,
  lib,

  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;

  cfg = config.khanelinix.services.syncthing;
in
{
  options.khanelinix.services.syncthing = {
    enable = mkEnableOption "syncthing";
  };

  config = mkIf cfg.enable {
    services.syncthing = {
      enable = true;

      tray.enable = pkgs.stdenv.hostPlatform.isLinux;
    };
  };
}
