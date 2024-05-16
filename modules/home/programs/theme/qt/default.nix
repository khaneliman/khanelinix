{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) types mkIf mergeAttrs;
  inherit (lib.internal) capitalize mkBoolOpt mkOpt;

  cfg = config.khanelinix.programs.theme.qt;
  themeCfg = config.khanelinix.desktop.theme;

  settings = {
    Appearance = {
      color_scheme_path = "";
      custom_palette = true;
      icon_theme = config.khanelinix.desktop.theme.icon.name;
      standard_dialogs = "gtk3";
      style = "kvantum";
    };

    Fonts = {
      fixed = "MonaspiceKr Nerd Font 10";
      general = "MonaspiceNe Nerd Font 10";
    };

    Interface = {
      activate_item_on_single_click = 1;
      buttonbox_layout = 0;
      cursor_flash_time = 1000;
      dialog_buttons_have_icons = 1;
      double_click_interval = 400;
      gui_effects = null; # You might need to adjust this depending on Nix version
      keyboard_scheme = 2;
      menus_have_icons = true;
      show_shortcuts_in_context_menus = true;
      stylesheets = null; # You might need to adjust this depending on Nix version
      toolbutton_style = "kvantum";
      underline_shortcut = 1;
      # wheel_scroll_lines = 3;
    };

    Troubleshooting = {
      force_raster_widgets = 1;
      ignored_applications = null; # You might need to adjust this depending on Nix version
    };
  };

  colorSchemePath = "${pkgs.catppuccin}/qt5ct/${capitalize themeCfg.selectedTheme.name}-${capitalize themeCfg.selectedTheme.variant}.conf";
in
{
  options.khanelinix.programs.theme.qt = with types; {
    enable = mkBoolOpt false "Whether to customize qt and apply themes.";
    theme = {
      name = mkOpt str "Catppuccin-Macchiato-Blue" "The name of the kvantum theme to apply.";
      package = mkOpt package (pkgs.catppuccin-kvantum.override {
        accent = "Blue";
        variant = "Macchiato";
      }) "The package to use for the theme.";
    };
  };

  config = mkIf cfg.enable {
    home = {
      packages = with pkgs; [
        # libraries and programs to ensure that qt applications load without issue
        # breeze-icons is added as a fallback
        breeze-icons
        kdePackages.qt6ct
        libsForQt5.qt5ct
        libsForQt5.qtstyleplugin-kvantum
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
      # TODO: replace with settings
      "Kvantum".source = ./Kvantum;
      "qt5ct/qt5ct.conf".text = lib.generators.toINI { } (
        settings
        // {
          Appearance = mergeAttrs settings.Appearance { color_scheme_path = colorSchemePath; };
        }
      );
      "qt6ct/qt6ct.conf".text = lib.generators.toINI { } (
        settings
        // {
          Appearance = mergeAttrs settings.Appearance { color_scheme_path = colorSchemePath; };
        }
      );
    };

    qt = {
      enable = true;

      platformTheme = {
        name = "qtct";
      };

      style = {
        name = "qt6ct-style";
        inherit (cfg.theme) package;
      };
    };
  };
}
