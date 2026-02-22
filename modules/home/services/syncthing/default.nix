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
      # Syncthing documentation
      # See: https://docs.syncthing.net/
      enable = true;

      tray.enable = pkgs.stdenv.hostPlatform.isLinux;
    };
  };
}
