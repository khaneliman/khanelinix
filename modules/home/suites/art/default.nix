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
    home.packages = with pkgs; [
      blender
      gimp
      inkscape-with-extensions
    ];
  };
}
