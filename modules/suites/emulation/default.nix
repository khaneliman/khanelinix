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
    khanelinix = {
      apps = {
        yuzu = enabled;
        pcsx2 = enabled;
        dolphin = enabled;
      };
    };
  };
}
