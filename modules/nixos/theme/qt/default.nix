{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib)
    types
    concatStringsSep
    mkIf
    ;
  inherit (lib.khanelinix) mkOpt;

  cfg = config.khanelinix.theme.qt;
  fontCfg = config.khanelinix.fonts;

  qtctFormat = pkgs.formats.ini {
    listToValue = values: concatStringsSep ", " values;
  };

  # Root-launched Qt apps do not see the Home Manager-managed qtct/Kvantum files
  # under ~/.config, so provide a system-wide fallback in /etc/xdg.
  qtctSettings = {
    Appearance = {
      custom_palette = true;
      standard_dialogs = "gtk3";
      style = "kvantum";
    };

    Fonts = {
      fixed = "${fontCfg.monaspace.families.krypton} 10";
      general = "${fontCfg.monaspace.families.neon} 10";
    };

    Interface = {
      activate_item_on_single_click = 1;
      buttonbox_layout = 0;
      cursor_flash_time = 1000;
      dialog_buttons_have_icons = 1;
      double_click_interval = 400;
      keyboard_scheme = 2;
      menus_have_icons = true;
      show_shortcuts_in_context_menus = true;
      toolbutton_style = "kvantum";
      underline_shortcut = 1;
    };

    Troubleshooting = {
      force_raster_widgets = 1;
    };
  };

  kvantumSettings = {
    General.theme = cfg.theme.name;
  };
in
{
  options.khanelinix.theme.qt = with types; {
    enable = lib.mkEnableOption "customizing qt and apply themes";

    theme = {
      name = mkOpt str "Catppuccin-Macchiato-Blue" "The name of the kvantum theme to apply.";
      package = mkOpt package (pkgs.catppuccin-kvantum.override {
        accent = "blue";
        variant = "macchiato";
      }) "The package to use for the theme.";
    };
  };

  config = mkIf cfg.enable {
    environment = {
      etc = {
        "xdg/Kvantum/kvantum.kvconfig".source = qtctFormat.generate "kvantum.kvconfig" kvantumSettings;
        "xdg/qt5ct/qt5ct.conf".source = qtctFormat.generate "qt5ct.conf" qtctSettings;
        "xdg/qt6ct/qt6ct.conf".source = qtctFormat.generate "qt6ct.conf" qtctSettings;
      };

      systemPackages =
        with pkgs;
        [ cfg.theme.package ] ++ lib.optional config.khanelinix.suites.wlroots.enable kdePackages.qtwayland;
    };

    qt = {
      enable = true;

      platformTheme = lib.mkDefault "qt5ct";
      style = lib.mkDefault "kvantum";
    };
  };
}
