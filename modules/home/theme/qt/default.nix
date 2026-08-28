{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    types
    mkDefault
    mkIf
    mkOption
    ;

  # Use direct implementations to avoid circular dependency
  mkOpt =
    type: default: description:
    mkOption { inherit type default description; };
  mkBoolOpt = mkOpt types.bool;

  cfg = config.khanelinix.theme.qt;
  fontCfg = config.khanelinix.fonts;
  inherit (pkgs.stdenv.hostPlatform) isLinux;

  qtQuickControlsConfig = "${config.xdg.configHome}/qtquickcontrols2.conf";
  qtQuickControlsFormat = pkgs.formats.ini { };
  qtQuickControlsPalette = lib.mapAttrs' (
    role: color: lib.nameValuePair "Palette\\${role}" color
  ) cfg.qml.palette;
  qtQuickControlsSettings = lib.genAttrs [
    "Basic"
    "Default"
    "Fusion"
    "Imagine"
    "Material"
    "Universal"
  ] (_: qtQuickControlsPalette);
  qtctSettings = lib.mapAttrs (
    _: section: lib.filterAttrs (_: value: value != null) section
  ) cfg.settings;
in
{
  options.khanelinix.theme.qt = with types; {
    enable = lib.mkEnableOption "Qt theming";

    theme = {
      name = mkOpt str "catppuccin-macchiato-blue" "The name of the kvantum theme to apply.";
      package = mkOpt package (
        if isLinux then
          pkgs.catppuccin-kvantum.override {
            accent = "blue";
            variant = "macchiato";
          }
        else
          pkgs.emptyDirectory
      ) "The package to use for the theme.";
    };

    qml.palette = mkOpt (attrsOf str) { } "Qt Quick Controls palette";

    settings = {
      Appearance = {
        color_scheme_path = mkOpt types.str "" "Color scheme path";
        custom_palette = mkBoolOpt false "Whether to use custom palette";
        icon_theme = mkOpt types.str (
          if isLinux then config.khanelinix.theme.gtk.icon.name else ""
        ) "Icon theme";
        standard_dialogs = mkOpt types.str "gtk3" "Dialog type";
        style = mkOpt types.str "kvantum" "Style";
      };

      Fonts = {
        fixed = mkOpt types.str ''"${fontCfg.monaspace.families.krypton},12"'' "Fixed font type";
        general = mkOpt types.str ''"Lexend,12"'' "General font type";
      };

      Interface = {
        activate_item_on_single_click = mkOpt types.int 1 "Whether to activate item on single click";
        buttonbox_layout = mkOpt types.int 0 "Buttonbox layout";
        cursor_flash_time = mkOpt types.int 1000 "Cursor flash time";
        dialog_buttons_have_icons = mkOpt types.int 1 "Whether dialog buttons have icons";
        double_click_interval = mkOpt types.int 400 "Double click interval";
        gui_effects = mkOpt (types.nullOr types.int) null "qtct GUI effects bitmask";
        keyboard_scheme = mkOpt types.int 2 "keyboard_scheme";
        menus_have_icons = mkBoolOpt true "Whether menus have icons";
        show_shortcuts_in_context_menus = mkBoolOpt true "Show shortcuts in context menus";
        stylesheets = mkOpt (types.nullOr (types.listOf types.str)) null "Stylesheets";
        toolbutton_style = mkOpt types.int 4 "Toolbutton style";
        underline_shortcut = mkOpt types.int 1 "Whether to underline shortcuts";
      };

      Troubleshooting = {
        force_raster_widgets = mkOpt types.int 1 "qtct raster widget mode";
        ignored_applications = mkOpt (types.nullOr (
          types.listOf types.str
        )) null "List of applications to ignore";
      };
    };
  };

  config = mkIf (cfg.enable && isLinux) {
    home = {
      packages = with pkgs; [
        kdePackages.breeze-icons
        kdePackages.qqc2-desktop-style
        libsForQt5.qtstyleplugin-kvantum
        qt6.qtsvg
        qt6.qtwayland
        qt6Packages.qtstyleplugin-kvantum
      ];

      sessionVariables = {
        # use wayland as the default backend, fallback to xcb if wayland is not available
        QT_QPA_PLATFORM = "wayland;xcb";
        # disable window decorations everywhere
        QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
      }
      // lib.optionalAttrs (cfg.qml.palette != { }) {
        QT_QUICK_CONTROLS_CONF = qtQuickControlsConfig;
      };
    };

    systemd.user.sessionVariables.QT_QUICK_CONTROLS_CONF = lib.mkIf (
      cfg.qml.palette != { }
    ) qtQuickControlsConfig;

    xdg.configFile."qtquickcontrols2.conf" = lib.mkIf (cfg.qml.palette != { }) {
      source = qtQuickControlsFormat.generate "qtquickcontrols2.conf" qtQuickControlsSettings;
    };

    qt = {
      enable = true;

      kvantum = {
        enable = true;
        themes = [ cfg.theme.package ];
        settings = {
          General.theme = cfg.theme.name;
        };
      };

      platformTheme = {
        name = mkDefault "qtct";
      };

      qt5ctSettings = qtctSettings;
      qt6ctSettings = qtctSettings;
    };
  };
}
