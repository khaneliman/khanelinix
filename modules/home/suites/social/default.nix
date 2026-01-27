{
  config,
  lib,

  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.khanelinix) enabled;

  cfg = config.khanelinix.suites.social;
in
{
  options.khanelinix.suites.social = {
    enable = lib.mkEnableOption "social configuration";
  };

  config = mkIf cfg.enable {
    home.packages =
      with pkgs;
      [
        element-desktop
      ]
      ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [
        # TODO: migrate to darwin after version bump
        slack
        telegram-desktop
      ];

    khanelinix = {
      programs = {
        graphical.apps = {
          caprine = lib.mkDefault enabled;
          # FIXME: broken darwin
          vesktop = mkIf pkgs.stdenv.hostPlatform.isLinux (lib.mkDefault enabled);
        };

        terminal.social = {
          slack-term = lib.mkDefault enabled;
          twitch-tui = lib.mkDefault enabled;
        };
      };
    };
  };
}
