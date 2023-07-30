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
      proton-caller
      protontricks
      protonup-ng
      bottles
      gamescope
    ];

    khanelinix = {
      apps = {
        steam = enabled;
        lutris = enabled;
        mangohud = enabled;
        gamemode = enabled;
      };

      cli-apps = {
        wine = enabled;
      };
    };
  };
}
