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
    enable = lib.mkEnableOption "Dolphin GameCube/Wii emulator";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.dolphin-emu ];

    # GameCube USB adapters require the emulator's device rules.
    services.udev.packages = [ pkgs.dolphin-emu ];
  };
}
