{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.programs.terminal.tools.wine;
in
{
  options.${namespace}.programs.terminal.tools.wine = {
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
