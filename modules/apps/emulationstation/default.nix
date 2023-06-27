{
  options,
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.apps.emulationstation;
in {
  options.khanelinix.apps.emulationstation = with types; {
    enable = mkBoolOpt false "Whether or not to enable emulationstation.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      emulationstation
    ];
  };
}
