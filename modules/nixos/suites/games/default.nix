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
    environment.systemPackages = with pkgs; [
      bottles
      lutris
      minecraft
      prismlauncher
      proton-caller
      protontricks
      protonup-ng
      protonup-qt
    ];

    khanelinix = {
      apps = {
        gamemode = enabled;
        gamescope = enabled;
        # mangohud = enabled;
        steam = enabled;
      };

      cli-apps = {
        wine = enabled;
      };
    };
  };
}
