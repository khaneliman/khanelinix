{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
let
  inherit (lib.${namespace}) capitalize;
  cfg = config.${namespace}.theme.catppuccin;
in
{
  config = lib.mkIf cfg.enable {
    khanelinix = {
      theme = {
        qt = lib.mkIf pkgs.stdenv.isLinux {
          theme = {
            name = "Catppuccin-Macchiato-Blue";
            package = pkgs.catppuccin-kvantum.override {
              accent = "blue";
              variant = "macchiato";
            };
          };

          settings = {
            Appearance = {
              color_scheme_path = "${pkgs.catppuccin}/qt5ct/Catppuccin-${capitalize cfg.flavor}.conf";
            };
          };
        };
      };
    };

    qt = lib.mkIf pkgs.stdenv.isLinux {
      enable = true;

      platformTheme = {
        name = "qtct";
      };

      style = {
        name = "kvantum";
        inherit (config.${namespace}.theme.qt.theme) package;
      };
    };
  };
}
