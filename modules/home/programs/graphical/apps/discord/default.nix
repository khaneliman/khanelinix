{
  config,
  inputs,
  lib,
  namespace,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf getExe;
  inherit (lib.${namespace}) mkBoolOpt;
  inherit (inputs) home-manager;

  cfg = config.${namespace}.programs.graphical.apps.discord;
in
{
  options.${namespace}.programs.graphical.apps.discord = {
    enable = mkBoolOpt false "Whether or not to enable Discord.";
    canary.enable = mkBoolOpt false "Whether or not to enable Discord Canary.";
    firefox.enable = mkBoolOpt false "Whether or not to enable the Firefox version of Discord.";
  };

  config = mkIf cfg.enable {
    home = {
      packages =
        lib.optional cfg.enable pkgs.discord
        ++ lib.optional cfg.canary.enable pkgs.${namespace}.discord
        ++ lib.optional cfg.firefox.enable pkgs.${namespace}.discord-firefox;

      activation = mkIf pkgs.stdenv.isLinux {
        betterdiscordInstall = # bash
          home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            echo "Running BetterDiscord install"

            BETTERDISCORDCTL=${getExe pkgs.betterdiscordctl}

            if $BETTERDISCORDCTL status; then
              echo "BetterDiscord is already installed. Attempting reinstallation..."
              $BETTERDISCORDCTL reinstall || {
                echo "Reinstallation failed! Attempting uninstallation..."
                $BETTERDISCORDCTL uninstall || {
                  echo "Uninstallation failed! Please check manually."
                  exit 1
                }
                echo "Uninstallation successful. Attempting fresh installation..."
                $BETTERDISCORDCTL install || {
                  echo "Installation failed!"
                  exit 1
                }
                echo "BetterDiscord installed successfully after uninstallation."
              }
            else
              echo "BetterDiscord is not installed. Attempting installation..."
              $BETTERDISCORDCTL install || {
                echo "Installation failed!"
                exit 1
              }
              echo "BetterDiscord installed successfully."
            fi
          '';

      };
    };
  };
}
