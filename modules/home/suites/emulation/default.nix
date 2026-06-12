{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.khanelinix) mkPackageProfileOption;

  cfg = config.khanelinix.suites.emulation;
in
{
  options.khanelinix.suites.emulation = {
    enable = lib.mkEnableOption "emulation configuration";
    packageProfile = mkPackageProfileOption "Package profile override for emulation applications.";
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
        #FIXME: broken by https://github.com/NixOS/nixpkgs/pull/412425
        # emulationstation
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
