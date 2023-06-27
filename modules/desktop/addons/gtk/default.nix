{
  options,
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.desktop.addons.gtk;
  gdmCfg = config.services.xserver.displayManager.gdm;
  default-attrs = mapAttrs (key: mkDefault);
  nested-default-attrs = mapAttrs (key: default-attrs);
in {
  options.khanelinix.desktop.addons.gtk = with types; {
    enable = mkBoolOpt false "Whether to customize GTK and apply themes.";
    theme = {
      name =
        mkOpt str "Catppuccin-Macchiato-Standard-Blue-dark"
        "The name of the GTK theme to apply.";
      pkg =
        mkOpt package
        (pkgs.catppuccin-gtk.override
          {
            accents = ["blue"];
            size = "standard";
            variant = "macchiato";
          }) "The package to use for the theme.";
    };
    cursor = {
      name =
        mkOpt str "Catppuccin-Macchiato-Blue-Cursors"
        "The name of the cursor theme to apply.";
      pkg = mkOpt package pkgs.catppuccin-cursors.macchiatoBlue "The package to use for the cursor theme.";
    };
    icon = {
      name =
        mkOpt str "Papirus-Dark"
        "The name of the icon theme to apply.";
      pkg = mkOpt package pkgs.papirus-icon-theme "The package to use for the icon theme.";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      cfg.icon.pkg
      cfg.cursor.pkg
      cfg.theme.pkg
      gsettings-desktop-schemas
      glib
      gtk3.out # for gtk-launch
    ];

    environment.sessionVariables = {
      XCURSOR_THEME = cfg.cursor.name;
      CURSOR_THEME = cfg.cursor.name;
    };

    services = {
      # needed for GNOME services outside of GNOME Desktop
      dbus.packages = [pkgs.gcr];
      udev.packages = with pkgs; [gnome.gnome-settings-daemon];
    };

    khanelinix.home = {
      file = {
        ".themes/${cfg.theme.name}".source = cfg.theme.pkg.outPath + "/share/themes/${cfg.theme.name}/";
      };
      configFile = {
        "gtk-3.0/assets".source = cfg.theme.pkg.outPath + "/share/themes/${cfg.theme.name}/gtk-3.0/assets/";
        "gtk-3.0/gtk.css".source = cfg.theme.pkg.outPath + "/share/themes/${cfg.theme.name}/gtk-3.0/gtk.css";
        "gtk-3.0/gtk-dark.css".source = cfg.theme.pkg.outPath + "/share/themes/${cfg.theme.name}/gtk-3.0/gtk-dark.css";
        "gtk-4.0/assets".source = cfg.theme.pkg.outPath + "/share/themes/${cfg.theme.name}/gtk-4.0/assets/";
        "gtk-4.0/gtk.css".source = cfg.theme.pkg.outPath + "/share/themes/${cfg.theme.name}/gtk-4.0/gtk.css";
        "gtk-4.0/gtk-dark.css".source = cfg.theme.pkg.outPath + "/share/themes/${cfg.theme.name}/gtk-4.0/gtk-dark.css";
      };

      extraOptions = {
        home.pointerCursor = {
          package = cfg.cursor.pkg;
          name = cfg.cursor.name;
          size = 32;
          gtk.enable = true;
          x11.enable = true;
        };

        gtk = {
          enable = true;

          theme = {
            name = cfg.theme.name;
            package = cfg.theme.pkg;
          };

          cursorTheme = {
            name = cfg.cursor.name;
            package = cfg.cursor.pkg;
          };

          iconTheme = {
            name = cfg.icon.name;
            package = cfg.icon.pkg;
          };

          font = {
            name = config.khanelinix.system.fonts.default;
          };
        };

        dconf = {
          enable = true;

          settings = nested-default-attrs {
            "org/gnome/desktop/interface" = {
              color-scheme = "prefer-dark";
              enable-hot-corners = false;
              font-theme = config.khanelinix.system.fonts.default;
              gtk-theme = cfg.theme.name;
              cursor-theme = cfg.cursor.name;
              icon-theme = cfg.icon.name;
            };
          };
        };
      };
    };
  };
}
