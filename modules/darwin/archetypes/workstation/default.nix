{
  config,
  lib,

  ...
}:
let
  inherit (flake.inputs.self.lib.khanelinix) mkBoolOpt enabled;

  cfg = config.khanelinix.archetypes.workstation;
in
{
  options.khanelinix.archetypes.workstation = {
    enable = mkBoolOpt false "Whether or not to enable the workstation archetype.";
  };

  config = lib.mkIf cfg.enable {
    khanelinix = {
      # TODO: input-leap replace barrier

      suites = {
        business = enabled;
        common = enabled;
        desktop = enabled;
        development = enabled;
      };
    };
  };
}
