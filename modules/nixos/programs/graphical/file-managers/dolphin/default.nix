{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.khanelinix.programs.graphical.file-managers.dolphin;
in
{
  options.khanelinix.programs.graphical.file-managers.dolphin = {
    enable = lib.mkEnableOption "Dolphin";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ dolphin-emu ];

    # Enable GameCube controller support.
    services.udev.packages = [ pkgs.dolphinEmu ];
  };
}
