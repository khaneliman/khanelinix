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
    khanelinix.theme.qt = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
      theme = {
        # Tokyonight does not ship a Kvantum theme in nixpkgs, so use the
        # Catppuccin Kvantum theme as the Qt fallback.
        name = "catppuccin-macchiato-blue";
        package = pkgs.catppuccin-kvantum.override {
          accent = "blue";
          variant = "macchiato";
        };
      };
    };
  };
}
