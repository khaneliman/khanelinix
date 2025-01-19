{
  config,
  khanelinix-lib,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (khanelinix-lib) mkBoolOpt;

  cfg = config.khanelinix.programs.graphical.apps.retroarch;
in
{
  options.khanelinix.programs.graphical.apps.retroarch = {
    enable = mkBoolOpt false "Whether or not to enable retroarch.";
  };

  config = mkIf cfg.enable {
    home.packages = [
      (pkgs.retroarch.withCores (
        cores: with cores; [
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
        ]
      ))
    ];
  };
}
