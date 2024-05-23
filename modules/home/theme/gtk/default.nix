{
  config,
  lib,
  pkgs,
  osConfig,
  namespace,
  ...
}:
let
  inherit (lib) mkIf mkDefault types;
  inherit (lib.${namespace})
    boolToNum
    mkBoolOpt
    mkOpt
    nested-default-attrs
    ;

  cfg = config.${namespace}.theme.gtk;
in
{
  options.${namespace}.theme.gtk = {
    enable = mkBoolOpt false "Whether to customize GTK and apply themes.";
    usePortal = mkBoolOpt false "Whether to use the GTK Portal.";

    cursor = {
      name = mkOpt types.str "Catppuccin-Macchiato-Blue-Cursors" "The name of the cursor theme to apply.";
      package = mkOpt types.package (
        if pkgs.stdenv.isLinux then pkgs.catppuccin-cursors.macchiatoBlue else pkgs.emptyDirectory
      ) "The package to use for the cursor theme.";
      size = mkOpt types.int 32 "The size of the cursor.";
    };

    icon = {
      name = mkOpt types.str "Papirus-Dark" "The name of the icon theme to apply.";
      package = mkOpt types.package (pkgs.catppuccin-papirus-folders.override {
        accent = "blue";
        flavor = "macchiato";
      }) "The package to use for the icon theme.";
    };

    theme = {
      name = mkOpt types.str "Catppuccin-Macchiato-Blue-Dark" "The name of the theme to apply";
      package = mkOpt types.package (pkgs.catppuccin-gtk.override {
        accents = [ "blue" ];
        size = "standard";
        tweaks = [ "normal" ];
        variant = "macchiato";
      }) "The package to use for the theme";
    };
  };

  config = mkIf (cfg.enable && pkgs.stdenv.isLinux) {
    home = {
      packages = with pkgs; [
        dconf # required explicitly with noXlibs and home-manager
        glib # gsettings
        gtk3.out # for gtk-launch
        libappindicator-gtk3
      ];

      pointerCursor = mkDefault {
        inherit (cfg.cursor) name package size;
        x11.enable = true;
      };

      sessionVariables = {
        GTK_USE_PORTAL = "${toString (boolToNum cfg.usePortal)}";
        CURSOR_THEME = mkDefault cfg.cursor.name;
      };
    };

    dconf = {
      enable = true;

      settings = nested-default-attrs {
        "org/gnome/desktop/interface" = {
          color-scheme = "prefer-dark";
          cursor-size = cfg.cursor.size;
          cursor-theme = cfg.cursor.name;
          enable-hot-corners = false;
          font-name = osConfig.${namespace}.system.fonts.default;
          gtk-theme = cfg.theme.name;
          icon-theme = cfg.icon.name;
        };
      };
    };

    gtk = {
      enable = true;

      font = {
        name = osConfig.${namespace}.system.fonts.default;
      };

      gtk2 = {
        configLocation = "${config.xdg.configHome}/gtk-2.0/gtkrc";
        extraConfig = ''
          gtk-xft-antialias=1
          gtk-xft-hinting=1
          gtk-xft-hintstyle="hintslight"
          gtk-xft-rgba="rgb"
        '';
      };

      gtk3.extraConfig = {
        gtk-application-prefer-dark-theme = true;
        gtk-button-images = 1;
        gtk-decoration-layout = "appmenu:none";
        gtk-enable-event-sounds = 0;
        gtk-enable-input-feedback-sounds = 0;
        gtk-error-bell = 0;
        gtk-menu-images = 1;
        gtk-toolbar-icon-size = "GTK_ICON_SIZE_LARGE_TOOLBAR";
        gtk-toolbar-style = "GTK_TOOLBAR_BOTH";
        gtk-xft-antialias = 1;
        gtk-xft-hinting = 1;
        gtk-xft-hintstyle = "hintslight";
      };

      gtk4.extraConfig = {
        gtk-application-prefer-dark-theme = true;
        gtk-decoration-layout = "appmenu:none";
        gtk-enable-event-sounds = 0;
        gtk-enable-input-feedback-sounds = 0;
        gtk-error-bell = 0;
        gtk-xft-antialias = 1;
        gtk-xft-hinting = 1;
        gtk-xft-hintstyle = "hintslight";
      };
    };

    xdg.systemDirs.data =
      let
        schema = pkgs.gsettings-desktop-schemas;
      in
      [ "${schema}/share/gsettings-schemas/${schema.name}" ];
  };
}
