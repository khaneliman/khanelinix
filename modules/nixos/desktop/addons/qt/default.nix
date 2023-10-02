{ config
, lib
, options
, pkgs
, ...
}:
let
  inherit (lib) types mkIf;
  inherit (lib.internal) mkBoolOpt mkOpt;

  cfg = config.khanelinix.desktop.addons.qt;
in
{
  options.khanelinix.desktop.addons.qt = with types; {
    enable = mkBoolOpt false "Whether to customize qt and apply themes.";
    theme = {
      name =
        mkOpt str "Catppuccin-Macchiato-Blue"
          "The name of the kvantum theme to apply.";
      pkg = mkOpt package pkgs.catppuccin-kvantum "The package to use for the theme.";
    };
  };

  config = mkIf cfg.enable {
    environment = {
      sessionVariables = {
        QT_STYLE_OVERRIDE = "kvantum";
        QT_QPA_PLATFORMTHEME = "qt5ct";
      };

      systemPackages = with pkgs;
        [
          (cfg.theme.pkg.override {
            accent = "Blue";
            variant = "Macchiato";
          })
          libsForQt5.qt5ct
          libsForQt5.qtstyleplugin-kvantum
          qt6Packages.qt6ct
          qt6Packages.qtstyleplugin-kvantum
        ]
        ++ lib.optional config.khanelinix.suites.wlroots.enable libsForQt5.qt5.qtwayland;
    };

    qt = {
      enable = true;

      platformTheme = "qt5ct";
      style = {
        inherit (cfg.theme) name;
        package = cfg.theme.pkg.override {
          accent = "Blue";
          variant = "Macchiato";
        };
      };
    };
  };
}
