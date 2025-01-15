{
  config,
  lib,

  ...
}:
let
  inherit (lib) mkIf;
  inherit (flake.inputs.self.lib.khanelinix) mkBoolOpt enabled;

  cfg = config.khanelinix.archetypes.gaming;
in
{
  options.khanelinix.archetypes.gaming = {
    enable = mkBoolOpt false "Whether or not to enable the gaming archetype.";
  };

  config = mkIf cfg.enable {
    khanelinix.suites = {
      common = enabled;
      desktop = enabled;
      games = enabled;
      video = enabled;
    };
  };
}
