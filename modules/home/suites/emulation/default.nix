{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.khanelinix.suites.emulation;
in
{
  options.khanelinix.suites.emulation = {
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
        # FIXME: removed for unmaintained
        # duckstation
        #FIXME: broken by https://github.com/NixOS/nixpkgs/pull/412425
        # emulationstation
        mgba
        mupen64plus
        nestopia-ue
        rpcs3
        # TODO: replacement, removed upstream
        # ryujinx
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
