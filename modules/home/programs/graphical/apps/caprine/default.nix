{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;

  cfg = config.${namespace}.programs.graphical.apps.caprine;
in
{
  options.${namespace}.programs.graphical.apps.caprine = {
    enable = mkEnableOption "caprine";
  };

  config = mkIf cfg.enable {
    xdg.configFile = mkIf pkgs.stdenv.hostPlatform.isLinux {
      "Caprine/custom.css".source = ./custom.css;
    };

    home.file = mkIf pkgs.stdenv.hostPlatform.isDarwin {
      "Library/Application Support/Caprine/custom.css".source = ./custom.css;
    };
  };
}
