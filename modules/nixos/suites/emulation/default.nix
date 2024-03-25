{ config
, lib
, options
, pkgs
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt;

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
      # FIX: broken package
      # cemu
      emulationstation
      mame
      melonDS
      mgba
      mupen64plus
      nestopia-ue
      # FIX: broken package
      # pcsx2
      pcsxr
      # FIX: broken package
      # rpcs3
      snes9x
      xemu
      # NOTE: yuzu removed upstream, using alternative
      ryujinx
    ] ++ lib.optionals cfg.retroarchFull [ retroarchFull ];

    khanelinix = {
      apps = {
        retroarch.enable = if cfg.retroarchFull then false else true;
      };
    };
  };
}
