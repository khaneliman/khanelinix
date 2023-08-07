{ options
, config
, lib
, pkgs
, ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.suites.emulation;
in
{
  options.khanelinix.suites.emulation = with types; {
    enable =
      mkBoolOpt false "Whether or not to enable emulation configuration.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      cemu
      emulationstation
      mame
      melonDS
      mgba
      mupen64plus
      nestopia
      pcsx2
      pcsxr
      retroarch
      rpcs3
      snes9x
      xemu
      yuzu-early-access
    ];

    khanelinix = {
      apps = {
        dolphin = enabled;
        emulationstation = enabled;
        retroarch = enabled;
      };
    };
  };
}
