{
  config,
  lib,
  khanelinix-lib,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (khanelinix-lib) mkBoolOpt enabled;

  cfg = config.khanelinix.archetypes.personal;
in
{
  options.khanelinix.archetypes.personal = {
    enable = mkBoolOpt false "Whether or not to enable the personal archetype.";
  };

  config = mkIf cfg.enable {
    khanelinix = {
      services = {
        tailscale = enabled;
      };

      suites = {
        common = enabled;
        video = enabled;
      };
    };
  };
}
