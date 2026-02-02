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
        gtk = {
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
