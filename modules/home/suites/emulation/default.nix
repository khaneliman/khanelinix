{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.suites.emulation;
in
{
  options.${namespace}.suites.emulation = {
    enable = mkBoolOpt false "Whether or not to enable emulation configuration.";
    retroarchFull = mkBoolOpt false "Whether or not to enable emulation configuration.";
  };

  config = mkIf cfg.enable {
    home.packages =
      with pkgs;
      [
        cemu
        duckstation
        emulationstation
        mame
        mednafen
        melonDS
        mgba
        mupen64plus
        nestopia-ue
        pcsx2
        rpcs3
        snes9x
        xemu
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
