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

  # TODO: move to catppuccin nixpkg
  colorScheme = {
    ColorScheme = {
      active_colors = "#ffcad3f5, #ff1e2030, #ffa5adcb, #ff939ab7, #ff494d64, #ff6e738d, #ffcad3f5, #ffcad3f5, #ffcad3f5, #ff24273a, #ff1e2030, #ff8087a2, #ff8aadf4, #ff24273a, #ff8aadf4, #ffed8796, #ff24273a, #ffcad3f5, #ff181926, #ffcad3f5, #808087a2";
      disabled_colors = "#ffa5adcb, #ff1e2030, #ffa5adcb, #ff939ab7, #ff494d64, #ff6e738d, #ffa5adcb, #ffa5adcb, #ffa5adcb, #ff24273a, #ff1e2030, #ff8087a2, #ff8aadf4, #ff494d64, #ff8aadf4, #ffed8796, #ff24273a, #ffcad3f5, #ff181926, #ffcad3f5, #808087a2";
      inactive_colors = "#ffcdd6f4, #ff1e2030, #ffa5adcb, #ff939ab7, #ff494d64, #ff6e738d, #ffcad3f5, #ffcad3f5, #ffcad3f5, #ff24273a, #ff1e2030, #ff8087a2, #ff8aadf4, #ffa5adcb, #ff8aadf4, #ffed8796, #ff24273a, #ffcad3f5, #ff181926, #ffcad3f5, #808087a2";
    };
  };

  settings = {
    Appearance = {
      color_scheme_path = "";
      custom_palette = true;
      icon_theme = config.khanelinix.desktop.addons.gtk.icon.name;
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
      wheel_scroll_lines = 3;
    };

    Troubleshooting = {
      force_raster_widgets = 1;
      ignored_applications = null; # You might need to adjust this depending on Nix version
    };
  };
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
    xdg.configFile = {
      "Kvantum".source = ./Kvantum;
      "qt5ct/colors/Catppuccin-Macchiato.conf".text = lib.generators.toINI { } colorScheme;
      "qt5ct/qt5ct.conf".text = lib.generators.toINI { } (settings // {
        Appearance.color_scheme_path = "/home/${config.khanelinix.user.name}/.config/qt5ct/colors/Catppuccin-Macchiato.conf";
      });
      "qt6ct/colors/Catppuccin-Macchiato.conf".text = lib.generators.toINI { } colorScheme;
      "qt6ct/qt6ct.conf".text = lib.generators.toINI { } (settings // {
        Appearance.color_scheme_path = "/home/${config.khanelinix.user.name}/.config/qt6ct/colors/Catppuccin-Macchiato.conf";
      });
    };

    qt = {
      enable = true;

      platformTheme = "qtct";
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
