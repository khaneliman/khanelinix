{ lib, ... }:
let
  inherit (lib) mkOption types;
  mkOpt =
    type: default: description:
    mkOption { inherit type default description; };
in
{
  options.khanelinix.theme.wallpaper = {
    theme = mkOpt types.str "catppuccin" "Wallpaper theme namespace under wallpapers.";
    primary = mkOpt types.str "flatppuccin_macchiato.png" "Primary wallpaper filename.";
    secondary = mkOpt types.str "cat-sound.png" "Secondary wallpaper filename.";
    lock = mkOpt types.str "flatppuccin_macchiato.png" "Lock screen wallpaper filename.";
    list = mkOpt (types.listOf types.str) [
      "flatppuccin_macchiato.png"
      "cat_pacman.png"
      "cat-sound.png"
    ] "Wallpaper names used for wallpaper lists.";
  };
}
