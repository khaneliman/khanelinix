{ options
, config
, lib
, pkgs
, inputs
, ...
}:
with lib;
with lib.internal; let
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
    environment.systemPackages = with pkgs; [
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
    ];

    khanelinix.home = {
      configFile = with inputs; {
        # "kvantum/kvantum.kvconfig".source = (pkgs.formats.ini { }).generate "kvantum.kvconfig" {
        #   general.theme = cfg.theme.name;
        # };
        "Kvantum".source = dotfiles.outPath + "/dots/linux/hyprland/home/.config/Kvantum/";
        "qt5ct".source = dotfiles.outPath + "/dots/linux/hyprland/home/.config/qt5ct/";
        "qt6ct".source = dotfiles.outPath + "/dots/linux/hyprland/home/.config/qt6ct/";
      };
    };

    qt = {
      enable = true;

      platformTheme = "qt5ct";
      style = {
        name = cfg.theme.name;
        package = (cfg.theme.pkg.override {
          accent = "Blue";
          variant = "Macchiato";
        });
      };
    };
  };
}
