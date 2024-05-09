{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    types
    mkIf
    mapAttrs
    mkDefault
    ;
  inherit (lib.internal) boolToNum mkBoolOpt mkOpt;

  cfg = config.khanelinix.programs.theme.gtk;
  themeCfg = config.khanelinix.desktop.theme;

  default-attrs = mapAttrs (_key: mkDefault);
  nested-default-attrs = mapAttrs (_key: default-attrs);
in
{
  options.khanelinix.programs.theme.gtk = {
    enable = mkBoolOpt false "Whether to customize GTK and apply themes.";
    theme = {
      name =
        mkOpt types.str "Catppuccin-Macchiato-Standard-Blue-Dark"
          "The name of the GTK theme to apply.";
      package = mkOpt types.package (pkgs.catppuccin-gtk.override {
        accents = [ "blue" ];
        size = "standard";
        variant = "macchiato";
      }) "The package to use for the theme.";
    };
    usePortal = mkBoolOpt false "Whether to use the GTK Portal.";
  };

  config = mkIf cfg.enable {
    home = {
      packages = with pkgs; [
        glib # gsettings
        cfg.theme.package
      ];

      sessionVariables = {
        GTK_THEME = cfg.theme.name;
        GTK_USE_PORTAL = "${toString (boolToNum cfg.usePortal)}";
      };
    };

    dconf = {
      enable = true;

      settings = nested-default-attrs {
        "org/gnome/desktop/interface" = {
          color-scheme = "prefer-dark";
          cursor-size = themeCfg.cursor.size;
          cursor-theme = themeCfg.cursor.name;
          enable-hot-corners = false;
          font-name = config.khanelinix.system.fonts.default;
          gtk-theme = cfg.theme.name;
          icon-theme = themeCfg.icon.name;
        };
      };
    };

    gtk = {
      enable = true;

      font = {
        name = config.khanelinix.system.fonts.default;
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

      iconTheme = {
        inherit (themeCfg.icon) name package;
      };

      theme = {
        inherit (cfg.theme) name package;
      };
    };

    home.pointerCursor = {
      gtk.enable = true;
    };

    xdg.systemDirs.data =
      let
        schema = pkgs.gsettings-desktop-schemas;
      in
      [ "${schema}/share/gsettings-schemas/${schema.name}" ];
  };
}
