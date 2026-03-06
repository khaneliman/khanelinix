{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.khanelinix.suites.art;
in
{
  options.khanelinix.suites.art = {
    enable = lib.mkEnableOption "art configuration";
    threeDimensionalEnable = lib.mkEnableOption "3d art applications";
    printingEnable = lib.mkEnableOption "3d printing applications";
  };

  config = mkIf cfg.enable {
    home.packages =
      with pkgs;
      [
        inkscape-with-extensions
        mediainfo
      ]
      ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux (
        [
          gimp
        ]
        ++ lib.optionals cfg.threeDimensionalEnable [
          # FIXME: marked broken on nixpkgs for darwin
          blender
        ]
        ++ lib.optionals cfg.printingEnable [
          flashprint
          orca-slicer
        ]
      );
  };
}
