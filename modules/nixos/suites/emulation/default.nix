{ config
, lib
, options
, pkgs
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt enabled;

  cfg = config.khanelinix.suites.emulation;
in
{
  options.khanelinix.suites.emulation = {
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
        retroarch = enabled;
      };
    };
  };
}
