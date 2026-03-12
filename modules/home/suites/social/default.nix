{
  config,
  lib,

  pkgs,
  pkgsUnstable,
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
      ++ [
        pkgsUnstable.telegram-desktop
      ];

    khanelinix = {
      programs = {
        graphical.apps = {
          caprine = lib.mkDefault enabled;
          # FIXME: broken darwin
          vesktop = mkIf pkgs.stdenv.hostPlatform.isLinux (lib.mkDefault enabled);
        };

        terminal.social = {
          twitch-tui = lib.mkDefault enabled;
        };
      };
    };
  };
}
