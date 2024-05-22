{ config, lib, ... }:
let
  inherit (lib) mkEnableOption mkIf;

  cfg = config.khanelinix.programs.graphical.apps.armcord;
in
{
  options.khanelinix.programs.graphical.apps.armcord = {
    enable = mkEnableOption "armcord";
  };

  config = mkIf cfg.enable {
    xdg.configFile = {
      # TODO: use theme module
      "ArmCord/themes/Catppuccin-Macchiato-BD".source = ./Catppuccin-Macchiato-BD;
    };
  };
}
