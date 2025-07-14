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
  };

  config = mkIf cfg.enable {
    # TODO: sober/roblox?
    home.packages = with pkgs; [
      bottles
      heroic
      lutris
      prismlauncher
      proton-caller
      protontricks
      protonup-ng
      protonup-qt
      umu-launcher
      wowup-cf
    ];

    khanelinix = {
      programs = {
        terminal = {
          tools = {
            wine = lib.mkDefault enabled;
          };
        };
      };
    };
  };
}
