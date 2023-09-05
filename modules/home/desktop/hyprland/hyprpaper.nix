{ config
, lib
, pkgs
, ...
}:
let
  inherit (lib) mkIf;
  cfg = config.khanelinix.desktop.hyprland;
in
{
  config =
    mkIf cfg.enable
      {
        xdg.configFile = {
          "hypr/hyprpaper.conf".text = ''
            # ░█░█░█▀█░█░░░█░░░█▀█░█▀█░█▀█░█▀▀░█▀▄░█▀▀
            # ░█▄█░█▀█░█░░░█░░░█▀▀░█▀█░█▀▀░█▀▀░█▀▄░▀▀█
            # ░▀░▀░▀░▀░▀▀▀░▀▀▀░▀░░░▀░▀░▀░░░▀▀▀░▀░▀░▀▀▀

            preload = ${pkgs.khanelinix.wallpapers}/share/wallpapers/buttons.png
            preload = ${pkgs.khanelinix.wallpapers}/share/wallpapers/cat_pacman.png
            preload = ${pkgs.khanelinix.wallpapers}/share/wallpapers/cat-sound.png
            preload = ${pkgs.khanelinix.wallpapers}/share/wallpapers/flatppuccin_macchiato.png
            preload = ${pkgs.khanelinix.wallpapers}/share/wallpapers/hashtags-black.png
            preload = ${pkgs.khanelinix.wallpapers}/share/wallpapers/hashtags-new.png
            preload = ${pkgs.khanelinix.wallpapers}/share/wallpapers/hearts.png
            preload = ${pkgs.khanelinix.wallpapers}/share/wallpapers/tetris.png

            wallpaper = DP-3,${pkgs.khanelinix.wallpapers}/share/wallpapers/cat_pacman.png
            wallpaper = DP-1,${pkgs.khanelinix.wallpapers}/share/wallpapers/cat-sound.png
          '';
        };
      };
}
