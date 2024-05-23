{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt enabled;

  cfg = config.${namespace}.suites.games;
in
{
  options.${namespace}.suites.games = {
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
