{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt;

  cfg = config.khanelinix.suites.emulation;
in
{
  options.khanelinix.suites.emulation = {
    enable = mkBoolOpt false "Whether or not to enable emulation configuration.";
    retroarchFull = mkBoolOpt false "Whether or not to enable emulation configuration.";
  };

  config = mkIf cfg.enable {
    home.packages =
      with pkgs;
      [
        cemu
        emulationstation
        mame
        melonDS
        mgba
        mupen64plus
        nestopia-ue
        pcsx2
        pcsxr
        rpcs3
        snes9x
        xemu
        # NOTE: yuzu removed upstream, using alternative
        ryujinx
      ]
      ++ lib.optionals cfg.retroarchFull [ retroarchFull ];

    khanelinix = {
      programs = {
        graphical = {
          apps = {
            retroarch.enable = if cfg.retroarchFull then false else true;
          };
        };
      };
    };
  };
}