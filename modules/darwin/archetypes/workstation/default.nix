{
  config,
  lib,

  ...
}:
let
  inherit (lib.khanelinix) enabled;

  cfg = config.khanelinix.archetypes.workstation;
in
{
  options.khanelinix.archetypes.workstation = {
    enable = lib.mkEnableOption "the workstation archetype";
  };

  config = lib.mkIf cfg.enable {
    homebrew = {
      taps = [
        "deskflow/homebrew-tap"
      ];
      casks = [ "deskflow" ];
    };

    khanelinix = {
      suites = {
        business = enabled;
        common = enabled;
        desktop = enabled;
        development = enabled;
      };
    };
  };
}
