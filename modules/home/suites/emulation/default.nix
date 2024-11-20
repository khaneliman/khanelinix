{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) mkIf;
  inherit (flake.inputs.self.lib.khanelinix) mkBoolOpt;

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
        mame
        mednafen
        melonDS
        pcsx2
        snes9x
      ]
      ++ lib.optionals stdenv.isLinux [
        cemu
        duckstation
        emulationstation
        mgba
        mupen64plus
        nestopia-ue
        rpcs3
        ryujinx
        xemu
      ]
      ++ lib.optionals cfg.retroarchFull [ retroarchFull ];

    khanelinix = {
      programs = {
        graphical = {
          apps = {
            retroarch.enable = if cfg.retroarchFull then lib.mkDefault false else lib.mkDefault true;
          };
        };
      };
    };
  };
}
