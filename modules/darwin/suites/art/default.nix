{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.${namespace}.suites.art;
in
{
  options.${namespace}.suites.art = {
    enable = lib.mkEnableOption "art configuration";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      imagemagick
      pngcheck
    ];

    homebrew = {
      casks = [
        "blender"
        "gimp"
        "inkscape"
        "mediainfo"
      ];

      masApps = mkIf config.${namespace}.tools.homebrew.masEnable { "Pixelmator" = 407963104; };
    };
  };
}
