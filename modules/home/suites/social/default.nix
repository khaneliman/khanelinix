{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) enabled;

  cfg = config.${namespace}.suites.social;
in
{
  options.${namespace}.suites.social = {
    enable = lib.mkEnableOption "social configuration";
  };

  config = mkIf cfg.enable {
    home.packages =
      with pkgs;
      [
        caprine-bin
        element-desktop
        telegram-desktop
      ]
      ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [
        # TODO: migrate to darwin after version bump
        slack
      ];

    khanelinix = {
      programs = {
        graphical.apps = {
          caprine = lib.mkDefault enabled;
          vesktop = lib.mkDefault enabled;
        };

        terminal.social = {
          slack-term = lib.mkDefault enabled;
          twitch-tui = lib.mkDefault enabled;
        };
      };
    };
  };
}
