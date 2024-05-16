{ config, lib, ... }:
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
    khanelinix = {
      programs = {
        graphical = {
          addons = {
            gamemode = enabled;
            gamescope = enabled;
            # mangohud = enabled;
          };

          apps = {
            steam = enabled;
          };
        };
      };
    };
  };
}
