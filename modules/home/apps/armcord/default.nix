{ config
, lib
, ...
}:
let
  inherit (lib) mkEnableOption mkIf;

  cfg = config.khanelinix.apps.armcord;
in
{
  options.khanelinix.apps.armcord = {
    enable = mkEnableOption "armcord";
  };

  config = mkIf cfg.enable {
    xdg.configFile = {
      "ArmCord/themes/Catppuccin-Macchiato-BD".source = ./Catppuccin-Macchiato-BD;
    };
  };
}

