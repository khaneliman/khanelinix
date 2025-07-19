{
  config,
  lib,

  pkgs,
  ...
}:
let
  cfg = config.khanelinix.theme.catppuccin;
in
{
  config = lib.mkIf cfg.enable {
    khanelinix = {
      theme = {
        gtk = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
          cursor = {
            name = "catppuccin-macchiato-blue-cursors";
            package = pkgs.catppuccin-cursors.macchiatoBlue;
            size = 32;
          };

          icon = {
            name = "Papirus-Dark";
            package = pkgs.catppuccin-papirus-folders.override {
              accent = "blue";
              flavor = "macchiato";
            };
          };

          theme = {
            name = "catppuccin-macchiato-blue-standard";
            package = pkgs.catppuccin-gtk.override {
              accents = [ "blue" ];
              variant = "macchiato";
            };
          };
        };
      };
    };
  };
}
