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

      # Device IDs only exist after the first run, so pairing stays manual. Keep
      # both override options off so devices and folder shares added in the web
      # interface survive the next activation.
      overrideDevices = false;
      overrideFolders = false;

      # Knowledge workspace shared with the zk notebook directory
      settings.folders.knowledge.path = "${config.home.homeDirectory}/${config.khanelinix.programs.terminal.tools.zk.notebookDirectory}";

      tray.enable = pkgs.stdenv.hostPlatform.isLinux;
    };

    systemd.user.services.syncthingtray = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
      Unit = {
        After = lib.mkAfter [ "xdg-desktop-portal.service" ];
        Wants = [ "xdg-desktop-portal.service" ];
      };
    };
  };
}
