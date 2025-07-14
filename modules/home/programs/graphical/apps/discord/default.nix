{
  config,
  inputs,
  lib,

  pkgs,
  ...
}:
let
  inherit (lib) mkIf getExe;
  inherit (inputs) home-manager;

  cfg = config.khanelinix.programs.graphical.apps.discord;
in
{
  options.khanelinix.programs.graphical.apps.discord = {
    enable = lib.mkEnableOption "Discord";
    canary.enable = lib.mkEnableOption "Discord Canary";
    firefox.enable = lib.mkEnableOption "the Firefox version of Discord";
  };

  config = mkIf cfg.enable {
    home = {
      packages =
        lib.optional cfg.enable pkgs.discord
        ++ lib.optional cfg.canary.enable pkgs.khanelinix.discord
        ++ lib.optional cfg.firefox.enable pkgs.khanelinix.discord-firefox;

      activation = mkIf pkgs.stdenv.hostPlatform.isLinux {
        betterdiscordInstall = # bash
          home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            echo "Running betterdiscord install"
            ${getExe pkgs.betterdiscordctl} install || ${getExe pkgs.betterdiscordctl} reinstall || true
          '';
      };
    };
  };
}
