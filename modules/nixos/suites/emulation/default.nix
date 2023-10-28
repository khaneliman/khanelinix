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
    retroarchFull =
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
      rpcs3
      snes9x
      xemu
      yuzu-early-access
    ] ++ lib.optionals cfg.retroarchFull [ retroarchFull ];

    khanelinix = {
      apps = {
        dolphin = enabled;
        retroarch.enable = mkIf cfg.retroarchFull == false;
      };
    };
  };
}
