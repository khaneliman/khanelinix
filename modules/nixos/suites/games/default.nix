{ config
, lib
, options
, pkgs
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt enabled;

  cfg = config.khanelinix.suites.games;
in
{
  options.khanelinix.suites.games = {
    enable =
      mkBoolOpt false "Whether or not to enable common games configuration.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      bottles
      gamescope
      lutris
      proton-caller
      protontricks
      protonup-ng
      protonup-qt
    ];

    khanelinix = {
      apps = {
        gamemode = enabled;
        # mangohud = enabled;
        steam = enabled;
      };

      cli-apps = {
        wine = enabled;
      };
    };
  };
}
