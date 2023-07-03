{
  options,
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.suites.emulation;
in {
  options.khanelinix.suites.emulation = with types; {
    enable =
      mkBoolOpt false "Whether or not to enable emulation configuration.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      rpcs3
      pcsx2
      cemu
      yuzu-early-access
      emulationstation
    ];

    khanelinix = {
      apps = {
        emulationstation = enabled;
        dolphin = enabled;
        retroarch = enabled;
      };
    };
  };
}
