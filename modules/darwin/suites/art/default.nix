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
    environment.systemPackages = with pkgs; [
      imagemagick
      pngcheck
    ];

    homebrew = {
      casks = [
        # FIXME: should be done through nixpkgs
        "blender"
        "gimp"
        "mediainfo"
        "orcaslicer"
      ];

      masApps = mkIf config.khanelinix.tools.homebrew.masEnable { "Pixelmator" = 407963104; };
    };
  };
}
