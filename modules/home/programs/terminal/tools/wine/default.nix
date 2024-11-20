{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.khanelinix) mkBoolOpt;

  cfg = config.khanelinix.programs.terminal.tools.wine;
in
{
  options.khanelinix.programs.terminal.tools.wine = {
    enable = mkBoolOpt false "Whether or not to enable Wine.";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      wineWowPackages.waylandFull
      # wine64Packages.waylandFull
      # winePackages.waylandFull
      winetricks
    ];
  };
}
