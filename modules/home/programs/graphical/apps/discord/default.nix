{
  config,
  inputs,
  khanelinix-lib,
  lib,
  pkgs,
  self,
  system,
  ...
}:
let
  inherit (lib) mkIf getExe;
  inherit (khanelinix-lib) mkBoolOpt;
  inherit (inputs) home-manager;

  cfg = config.khanelinix.programs.graphical.apps.discord;
in
{
  options.khanelinix.programs.graphical.apps.discord = {
    enable = mkBoolOpt false "Whether or not to enable Discord.";
    canary.enable = mkBoolOpt false "Whether or not to enable Discord Canary.";
    firefox.enable = mkBoolOpt false "Whether or not to enable the Firefox version of Discord.";
  };

  config = mkIf cfg.enable {
    home = {
      packages =
        lib.optional cfg.enable pkgs.discord
        ++ lib.optional cfg.canary.enable self.packages.${system}.discord
        ++ lib.optional cfg.firefox.enable self.packages.${system}.discord-firefox;

      activation = mkIf pkgs.stdenv.isLinux {
        betterdiscordInstall = # bash
          home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            echo "Running betterdiscord install"
            ${getExe pkgs.betterdiscordctl} install || ${getExe pkgs.betterdiscordctl} reinstall || true
          '';
      };
    };
  };
}
