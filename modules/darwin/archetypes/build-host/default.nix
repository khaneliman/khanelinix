{ config, lib, ... }:
let
  cfg = config.khanelinix.archetypes.build-host;
in
{
  options.khanelinix.archetypes.build-host.enable =
    lib.mkEnableOption "the Darwin build host archetype";

  config = lib.mkIf cfg.enable {
    khanelinix = {
      suites = {
        common.enable = lib.mkDefault true;
        networking.enable = lib.mkDefault true;
      };

      # These opt-outs override the common suite's defaults.
      services.time-machine.enable = false;
      tools.homebrew.enable = false;
    };
  };
}
