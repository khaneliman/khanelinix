{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.khanelinix) enabled;

  cfg = config.khanelinix.suites.games;
in
{
  options.khanelinix.suites.games = {
    enable = lib.mkEnableOption "common games configuration";
    protonToolsEnable = lib.mkEnableOption "proton and wine tools";
  };

  config = mkIf cfg.enable {
    # TODO: sober/roblox?
    home.packages =
      with pkgs;
      [
        moonlight-qt
      ]
      ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux (
        [
          wowup-cf
        ]
        ++ lib.optionals cfg.protonToolsEnable [
          bottles
          heroic
          lutris
          protontricks
          protonup-ng
          protonup-qt
          umu-launcher
        ]
      );

    khanelinix = {
      programs = {
        graphical = {
          apps.prismlauncher = lib.mkDefault enabled;
          mangohud = lib.mkDefault enabled;
        };

        terminal = {
          tools = {
            wine = mkIf cfg.protonToolsEnable (lib.mkDefault enabled);
          };
        };
      };
    };
  };
}
