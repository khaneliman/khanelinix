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
        melonds
        pcsx2
        snes9x
        xemu
      ]
      ++ lib.optionals stdenv.hostPlatform.isLinux [
        cemu
        mgba
        mupen64plus
        nestopia-ue
        # FIXME: broken nixpkgs again
        # rpcs3
      ]
      ++ lib.optionals cfg.retroarchFull [ retroarchFull ];

    khanelinix = {
      programs = {
        graphical = {
          apps = {
            retroarch.enable = lib.mkDefault (!cfg.retroarchFull);
          };
        };
      };
    };
  };
}
