{ options
, config
, lib
, pkgs
, ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.apps.retroarch;
in
{
  options.khanelinix.apps.retroarch = with types; {
    enable = mkBoolOpt false "Whether or not to enable retroarch.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      (retroarch.override {
        cores = with libretro; [
          genesis-plus-gx
          snes9x
          beetle-psx-hw
          beetle-snes
          citra
          dolphin
          mame
          mgba
          nestopia
          pcsx2
        ];
      })
    ];
  };
}
