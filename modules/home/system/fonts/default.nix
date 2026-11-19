{ config, lib, ... }:
let
  inherit (lib) types;
  inherit (lib.khanelinix) mkOpt;
in
{
  imports = [
    (lib.getFile "modules/common/fonts/default.nix")
  ]
  ++
    map
      (
        option:
        lib.mkAliasOptionModule
          [ "khanelinix" "home" "fonts" option ]
          [ "khanelinix" "system" "fonts" option ]
      )
      [
        "enable"
        "default"
        "size"
      ];

  options.khanelinix.system.fonts = {
    enable = lib.mkEnableOption "home-manager font settings";
    default =
      mkOpt types.str config.khanelinix.fonts.monaspace.families.neon
        "Default UI font family name";
    size = mkOpt types.int 13 "Default font size";
  };
}
