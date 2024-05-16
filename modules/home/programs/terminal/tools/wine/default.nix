{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt;

  cfg = config.khanelinix.programs.terminal.tools.wine;
in
{
  options.khanelinix.programs.terminal.tools.wine = {
    enable = mkBoolOpt false "Whether or not to enable Wine.";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      # winePackages.waylandFull
      winetricks
      wine64Packages.waylandFull
    ];
  };
}
