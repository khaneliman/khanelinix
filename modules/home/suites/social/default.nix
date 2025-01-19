{
  config,
  lib,
  khanelinix-lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (khanelinix-lib) mkBoolOpt enabled;

  cfg = config.khanelinix.suites.social;
in
{
  options.khanelinix.suites.social = {
    enable = mkBoolOpt false "Whether or not to enable social configuration.";
  };

  config = mkIf cfg.enable {
    home.packages =
      with pkgs;
      [
        caprine-bin
        element-desktop
        telegram-desktop
      ]
      ++ lib.optionals pkgs.stdenv.isLinux [
        # TODO: migrate to darwin after version bump
        slack
      ];

    khanelinix = {
      programs = {
        graphical.apps = {
          discord = lib.mkDefault enabled;
          caprine = lib.mkDefault enabled;
        };

        terminal.social = {
          slack-term = lib.mkDefault enabled;
          twitch-tui = lib.mkDefault enabled;
        };
      };
    };
  };
}
