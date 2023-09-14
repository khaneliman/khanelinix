{ options
, config
, lib
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
    environment.systemPackages = with pkgs;
      [
        (cfg.theme.pkg.override {
          accent = "Blue";
          variant = "Macchiato";
        })
        # TODO: get qt5 and qt6 to work together properly with sddm and xdph
        libsForQt5.qtstyleplugin-kvantum
        libsForQt5.qt5.qtgraphicaleffects
        libsForQt5.qt5.qtquickcontrols2
        libsForQt5.qt5.qtsvg
        libsForQt5.qt5ct
        # qt6.full
        # qt6.qtsvg
        # qt6.qtquick3d
        # qt6.wrapQtAppsHook
        # qt6.qtwayland
      ]
      ++ lib.optional config.khanelinix.suites.wlroots.enable libsForQt5.qt5.qtwayland;

    environment.sessionVariables = {
      QT_QPA_PLATFORMTHEME = "qt5ct";
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
