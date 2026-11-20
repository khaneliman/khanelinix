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

  # Fusion draws with the application palette, so a palette stands in for the
  # Kvantum theme when a theme family has none.
  usesPalette = cfg.palette != { };
  qtctColorScheme = pkgs.writeText "khanelinix-qtct-colors.conf" (
    lib.khanelinix.theme.qtctColorScheme cfg.palette
  );

  # Elevated Qt apps cannot read the user's Home Manager theme files.
  qtctSettings = {
    Appearance = {
      custom_palette = usesPalette;
      icon_theme = cfg.icon.name;
      standard_dialogs = "gtk3";
      style = if usesPalette then "fusion" else "kvantum";
    }
    // lib.optionalAttrs usesPalette {
      color_scheme_path = "${qtctColorScheme}";
    };

    Fonts = {
      fixed = ''"${fontCfg.monaspace.families.krypton},12"'';
      general = ''"Lexend,12"'';
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
      toolbutton_style = 4;
      underline_shortcut = 1;
    };

    Troubleshooting.force_raster_widgets = 1;
  };

  kvantumSettings.General.theme = cfg.theme.name;
  systemKvantumQt5 = pkgs.libsForQt5.qtstyleplugin-kvantum.overrideAttrs (oldAttrs: {
    postInstall = (oldAttrs.postInstall or "") + ''
      standardThemes=$(readlink "$out/share/Kvantum")
      rm "$out/share/Kvantum"
      mkdir "$out/share/Kvantum"
      cp -r "$standardThemes/." "$out/share/Kvantum/"
      cp -r ${cfg.theme.package}/share/Kvantum/${cfg.theme.name} "$out/share/Kvantum/"
    '';
  });
in
{
  options.khanelinix.theme.qt = with types; {
    enable = lib.mkEnableOption "customizing qt and apply themes";

    theme = {
      name = mkOpt str "catppuccin-macchiato-blue" "The name of the kvantum theme to apply.";
      package = mkOpt package (pkgs.catppuccin-kvantum.override {
        accent = "blue";
        variant = "macchiato";
      }) "The package to use for the theme.";
    };

    palette = mkOpt (attrsOf str) { } ''
      Qt palette, keyed by QPalette color role. When set, system Qt
      applications use Fusion with these colors instead of the Kvantum theme.
    '';

    icon = {
      name = mkOpt str "Papirus-Dark" "The icon theme to use for system Qt applications.";
      package = mkOpt package pkgs.papirus-icon-theme "The package providing the system Qt icon theme.";
    };
  };

  config = mkIf cfg.enable {
    environment = {
      etc = lib.mkMerge [
        {
          "xdg/qt5ct/qt5ct.conf".source = qtctFormat.generate "qt5ct.conf" qtctSettings;
          "xdg/qt6ct/qt6ct.conf".source = qtctFormat.generate "qt6ct.conf" qtctSettings;
        }
        (mkIf (!usesPalette) {
          "xdg/Kvantum/${cfg.theme.name}".source = "${cfg.theme.package}/share/Kvantum/${cfg.theme.name}";
          "xdg/Kvantum/kvantum.kvconfig".source = qtctFormat.generate "kvantum.kvconfig" kvantumSettings;
        })
      ];

      systemPackages =
        with pkgs;
        [ cfg.icon.package ]
        ++ lib.optionals (!usesPalette) [
          cfg.theme.package
          qt6Packages.qtstyleplugin-kvantum
          systemKvantumQt5
        ]
        ++ lib.optional config.khanelinix.suites.wlroots.enable kdePackages.qtwayland;
    };

    qt = {
      enable = true;
      platformTheme = lib.mkDefault "qt5ct";
    };
  };
}
