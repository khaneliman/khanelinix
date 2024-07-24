{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) types mkDefault mkIf;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;

  cfg = config.${namespace}.theme.qt;
in
{
  options.${namespace}.theme.qt = with types; {
    enable = mkBoolOpt false "Whether to customize qt and apply themes.";

    theme = {
      name = mkOpt str "Catppuccin-Macchiato-Blue" "The name of the kvantum theme to apply.";
      package = mkOpt package (pkgs.catppuccin-kvantum.override {
        accent = "Blue";
        variant = "Macchiato";
      }) "The package to use for the theme.";
    };

    settings = {
      Appearance = {
        color_scheme_path = mkOpt types.str "" "Color scheme path";
        custom_palette = mkBoolOpt true "Whether to use custom palette";
        icon_theme = mkOpt types.str config.${namespace}.theme.gtk.icon.name "Icon theme";
        standard_dialogs = mkOpt types.str "gtk3" "Dialog type";
        style = mkOpt types.str "kvantum" "Style";
      };

      Fonts = {
        fixed = mkOpt types.str "MonaspiceKr Nerd Font 10" "Fixed font type";
        general = mkOpt types.str "MonaspiceNe Nerd Font 10" "General font type";
      };

      Interface = {
        activate_item_on_single_click = mkOpt types.int 1 "Whether to activate item on single click";
        buttonbox_layout = mkOpt types.int 0 "Buttonbox layout";
        cursor_flash_time = mkOpt types.int 1000 "Cursor flash time";
        dialog_buttons_have_icons = mkOpt types.int 1 "Whether dialog buttons have icons";
        double_click_interval = mkOpt types.int 400 "Double click interval";
        gui_effects = mkOpt (types.nullOr types.int) null "Whether to enable effects"; # You might need to adjust this depending on Nix version
        keyboard_scheme = mkOpt types.int 2 "keyboard_scheme";
        menus_have_icons = mkBoolOpt true "Whether menus have icons";
        show_shortcuts_in_context_menus = mkBoolOpt true "Show shortcuts in context menus";
        stylesheets = mkOpt (types.nullOr (types.listOf types.str)) null "Stylesheets"; # You might need to adjust this depending on Nix version
        toolbutton_style = mkOpt types.str "kvantum" "Toolbutton style";
        underline_shortcut = mkOpt types.int 1 "Whether to underline shortcuts";
        # wheel_scroll_lines = 3;
      };

      Troubleshooting = {
        force_raster_widgets = mkOpt types.int 1 "Whether to force rastering of widgets";
        ignored_applications = mkOpt (types.nullOr (
          types.listOf types.str
        )) null "List of applications to ignore"; # You might need to adjust this depending on Nix version
      };
    };
  };

  config = mkIf (cfg.enable && pkgs.stdenv.isLinux) {
    home = {
      packages = with pkgs; [
        # libraries and programs to ensure that qt applications load without issue
        # kdePackages = qt6
        # libsForQt5 = qt5
        kdePackages.breeze-icons
        kdePackages.qqc2-desktop-style
        kdePackages.qt6ct
        kdePackages.qtwayland # qt6
        libsForQt5.breeze-qt5
        libsForQt5.qt5.qtwayland # qt5
        libsForQt5.qt5ct
        libsForQt5.qtstyleplugin-kvantum
        libsForQt5.qtstyleplugins
        qt6.qtsvg # needed to load breeze icons
        qt6.qtwayland
        qt6Packages.qt6gtk2
        qt6Packages.qtstyleplugin-kvantum
      ];

      sessionVariables = {
        # scaling - 1 means no scaling
        QT_AUTO_SCREEN_SCALE_FACTOR = "1";
        # use wayland as the default backend, fallback to xcb if wayland is not available
        QT_QPA_PLATFORM = "wayland;xcb";
        # disable window decorations everywhere
        QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
        # remain backwards compatible with qt5
        DISABLE_QT5_COMPAT = "0";
      };
    };

    xdg.configFile = {
      "Kvantum".source = ./Kvantum;
      "qt5ct/qt5ct.conf".text = lib.generators.toINI { } cfg.settings;
      "qt6ct/qt6ct.conf".text = lib.generators.toINI { } cfg.settings;
    };

    qt = {
      enable = true;

      platformTheme = {
        name = "qtct";
      };

      style = mkDefault { name = "qt6ct-style"; };
    };
  };
}
