{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.khanelinix.theme.tokyonight;
in
{
  config = lib.mkIf cfg.enable {
    khanelinix.theme.qt = {
      theme = {
        name = "catppuccin-macchiato-blue";
        package = pkgs.catppuccin-kvantum.override {
          accent = "blue";
          variant = "macchiato";
        };
      };
    };
  };
}
