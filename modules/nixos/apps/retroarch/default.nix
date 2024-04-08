{
  config,
  lib,
  pkgs,
  ...
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
          # TODO: replace after nixpkg hash fixed
          (mame.overrideAttrs (_old: {
            src = fetchFromGitHub {
              owner = "libretro";
              repo = "mame";
              rev = "ac9d0347f5d331eb49017cd599a5e63a668b4f22";
              hash = "sha256-YlnW5v8Slz/w/AHwWzJ7ZszFic/W0wth2nOZVOD7yxs=";
            };
          }))
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
