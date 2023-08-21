{ options
, config
, lib
, pkgs
, ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.suites.games;
in
{
  options.khanelinix.suites.games = with types; {
    enable =
      mkBoolOpt false "Whether or not to enable common games configuration.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      bottles
      gamescope
      proton-caller
      protontricks
      protonup-ng
      protonup-qt
    ];

    khanelinix = {
      apps = {
        gamemode = enabled;
        lutris = enabled;
        mangohud = enabled;
        steam = enabled;
      };

      cli-apps = {
        wine = enabled;
      };
    };
  };
}
