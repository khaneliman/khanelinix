{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt enabled;

  cfg = config.khanelinix.suites.games;
in
{
  options.khanelinix.suites.games = {
    enable = mkBoolOpt false "Whether or not to enable common games configuration.";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      bottles
      lutris
      # FIX: broken nixpkg
      # minecraft
      prismlauncher
      proton-caller
      protontricks
      protonup-ng
      protonup-qt
    ];

    khanelinix = {
      programs = {
        terminal = {
          tools = {
            wine = enabled;
          };
        };
      };
    };
  };
}
