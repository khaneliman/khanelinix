{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.${namespace}.suites.emulation;
in
{
  options.${namespace}.suites.emulation = {
    enable = lib.mkEnableOption "emulation configuration";
    retroarchFull = lib.mkEnableOption "emulation configuration";
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
      ++ lib.optionals stdenv.hostPlatform.isLinux [
        cemu
        duckstation
        emulationstation
        mgba
        # FIXME: broken nixpkgs
        # mupen64plus
        nestopia-ue
        # FIXME: broken nixpkgs
        # rpcs3
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
