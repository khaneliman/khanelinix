{
  config,
  lib,
  pkgs,

  ...
}:
let
  cfg = config.khanelinix.programs.graphical.apps.dolphin;
in
{
  imports = [
    (lib.mkRenamedOptionModule
      [ "khanelinix" "programs" "graphical" "file-managers" "dolphin" "enable" ]
      [ "khanelinix" "programs" "graphical" "apps" "dolphin" "enable" ]
    )
  ];

  options.khanelinix.programs.graphical.apps.dolphin = {
    enable = lib.mkEnableOption "Dolphin GameCube/Wii emulator";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.dolphin-emu ];

    # GameCube USB adapters require the emulator's device rules.
    services.udev.packages = [ pkgs.dolphin-emu ];
  };
}
