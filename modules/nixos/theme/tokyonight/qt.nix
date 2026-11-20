{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.khanelinix.theme.tokyonight;
  tokyonight = import (lib.getFile "modules/home/theme/tokyonight/colors.nix");
in
{
  config = lib.mkIf cfg.enable {
    khanelinix.theme.qt = {
      icon = {
        name = "Papirus-Dark";
        package = pkgs.papirus-icon-theme;
      };

      # Tokyo Night has no Kvantum theme in nixpkgs.
      palette = tokyonight.qtPalette cfg.variant;
    };
  };
}
