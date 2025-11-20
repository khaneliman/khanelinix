{
  config,
  lib,
  pkgs,
  osConfig ? { },
  ...
}:
let
  inherit (lib)
    mkIf
    mkDefault
    types
    ;
  inherit (lib.khanelinix) mkOpt boolToNum nested-default-attrs;

  cfg = config.khanelinix.theme.gtk;
in
{
  options.khanelinix.theme.gtk = {
    enable = lib.mkEnableOption "customizing GTK and apply themes";
    usePortal = lib.mkEnableOption "using the GTK Portal";

    cursor = {
      name = mkOpt types.str "catppuccin-macchiato-blue-cursors" "The name of the cursor theme to apply.";
      package = mkOpt types.package (
        if pkgs.stdenv.hostPlatform.isLinux then
          pkgs.catppuccin-cursors.macchiatoBlue
        else
          pkgs.emptyDirectory
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
      name = mkOpt types.str "catppuccin-macchiato-blue-standard" "The name of the theme to apply";
      package = mkOpt types.package (pkgs.catppuccin-gtk.override {
        accents = [ "blue" ];
        size = "standard";
        variant = "macchiato";
      }) "The package to use for the theme";
    };
  };

  config = mkIf (cfg.enable && pkgs.stdenv.hostPlatform.isLinux) {
    home = {
      packages = with pkgs; [
        # NOTE: required explicitly with noXlibs and home-manager
        dconf
        glib # gsettings
        gtk3.out # for gtk-launch
        libappindicator-gtk3
      ];

      pointerCursor = mkDefault {
        name = mkDefault cfg.cursor.name;
        package = mkDefault cfg.cursor.package;
        size = mkDefault cfg.cursor.size;
        gtk.enable = true;
        x11.enable = true;
      };

      sessionVariables = {
        GTK_USE_PORTAL = "${toString (boolToNum cfg.usePortal)}";
        CURSOR_THEME = mkDefault cfg.cursor.name;
      };
    };

    dbus.packages = [ pkgs.dconf ];

    dconf = {
      enable = true;

      settings = nested-default-attrs {
        "org/gnome/shell" = {
          disable-user-extensions = false;
          enabled-extensions = [ "user-theme@gnome-shell-extensions.gcampax.github.com" ];
        };

        "org/gnome/shell/extensions/user-theme" = {
          inherit (cfg.theme) name;
        };

        "org/gnome/desktop/interface" = {
          color-scheme = "prefer-dark";
          cursor-size = cfg.cursor.size;
          cursor-theme = cfg.cursor.name;
          font-name = "${osConfig.khanelinix.system.fonts.default or "MonaspaceNeon NF"} ${
            toString (osConfig.khanelinix.system.fonts.size or 10)
          }";
          gtk-theme = cfg.theme.name;
          icon-theme = cfg.icon.name;
        };
      };
    };

    gtk = {
      enable = true;

      font = {
        name = mkDefault (osConfig.khanelinix.system.fonts.default or "MonaspaceNeon NF");
        size = mkDefault (osConfig.khanelinix.system.fonts.size or 10);
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
        gtk-decoration-layout = "appmenu:none";
        gtk-enable-event-sounds = 0;
        gtk-enable-input-feedback-sounds = 0;
        gtk-error-bell = 0;
        gtk-xft-antialias = 1;
        gtk-xft-hinting = 1;
        gtk-xft-hintstyle = "hintslight";
      };

      iconTheme = {
        name = mkDefault cfg.icon.name;
        package = mkDefault cfg.icon.package;
      };

      theme = {
        name = mkDefault cfg.theme.name;
        package = mkDefault cfg.theme.package;
      };
    };

    xdg = {
      systemDirs.data =
        let
          schema = pkgs.gsettings-desktop-schemas;
        in
        [ "${schema}/share/gsettings-schemas/${schema.name}" ];
    };
  };
}
