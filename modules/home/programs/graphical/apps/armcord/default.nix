{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;

  cfg = config.${namespace}.programs.graphical.apps.armcord;
in
{
  options.${namespace}.programs.graphical.apps.armcord = {
    enable = mkEnableOption "armcord";
  };

  config = mkIf cfg.enable {
    xdg.configFile = {
      # TODO: use theme module
      "ArmCord/themes/Catppuccin-Macchiato-BD".source = ./Catppuccin-Macchiato-BD;
    };
  };
}
