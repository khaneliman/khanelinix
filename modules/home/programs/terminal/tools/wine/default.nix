{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.${namespace}.programs.terminal.tools.wine;
in
{
  options.${namespace}.programs.terminal.tools.wine = {
    enable = lib.mkEnableOption "Wine";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      winetricks
      # wineWowPackages.stable
      wineWowPackages.waylandFull
    ];
  };
}
