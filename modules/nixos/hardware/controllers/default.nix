{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf mkEnableOption mkMerge;

  cfg = config.khanelinix.hardware.controllers;
in
{
  options.khanelinix.hardware.controllers = {
    xpadneo.enable = mkEnableOption "xpadneo driver for Xbox wireless-over-Bluetooth controllers";
    playstation.enable = mkEnableOption "udev rules for PlayStation DualSense/DualShock controllers";
    joycon.enable = mkEnableOption "joycond support for Nintendo Joy-Con/Switch Pro controllers";
  };

  config = mkMerge [
    (mkIf cfg.xpadneo.enable {
      hardware.xpadneo.enable = true;
    })
    (mkIf cfg.playstation.enable {
      services.udev.packages = [ pkgs.game-devices-udev-rules ];
    })
    (mkIf cfg.joycon.enable {
      services.joycond.enable = true;
    })
  ];
}
