{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt;

  cfg = config.khanelinix.programs.graphical.apps.retroarch;
in
{
  options.khanelinix.programs.graphical.apps.retroarch = {
    enable = mkBoolOpt false "Whether or not to enable retroarch.";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      (retroarch.override {
        cores = with libretro; [
          beetle-psx-hw
          bsnes
          citra
          dolphin
          dosbox
          genesis-plus-gx
          mame
          mgba
          nestopia
          pcsx2
          snes9x
        ];
      })
    ];
  };
}
