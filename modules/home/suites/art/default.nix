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
  };

  config = mkIf cfg.enable {
    home.packages =
      with pkgs;
      [
        inkscape-with-extensions
      ]
      ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [
        # FIXME: marked broken on nixpkgs for darwin
        blender
        flashprint
        gimp
        orca-slicer
      ];
  };
}
