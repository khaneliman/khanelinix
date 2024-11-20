{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) mkIf;
  inherit (flake.inputs.self.lib.khanelinix) mkBoolOpt;

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
