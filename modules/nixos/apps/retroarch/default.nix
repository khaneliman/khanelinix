{ config
, lib
, options
, pkgs
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt;

  cfg = config.khanelinix.apps.retroarch;
in
{
  options.khanelinix.apps.retroarch = {
    enable = mkBoolOpt false "Whether or not to enable retroarch.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      (retroarch.override {
        cores = with libretro; [
          beetle-psx-hw
          bsnes
          # FIX: broken package
          # citra
          dolphin
          dosbox
          genesis-plus-gx
          mame
          mgba
          nestopia
          # FIX: broken package
          # pcsx2
          snes9x
        ];
      })
    ];
  };
}
