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
            name = "catppuccin-${cfg.flavor}-${cfg.accent}-cursors";
            package = pkgs.catppuccin-cursors.${cfg.flavor + lib.toSentenceCase cfg.accent};
            size = 32;
          };

          icon = {
            name = if cfg.flavor == "latte" then "Papirus-Light" else "Papirus-Dark";
            package = pkgs.catppuccin-papirus-folders.override {
              inherit (cfg) accent flavor;
            };
          };

          theme = {
            name = "catppuccin-${cfg.flavor}-${cfg.accent}-standard";
            package = pkgs.catppuccin-gtk.override {
              accents = [ cfg.accent ];
              variant = cfg.flavor;
            };
          };
        };
      };
    };
  };
}
