{ options
, config
, lib
, pkgs
, ...
}:
let
  inherit (lib) types mkIf mapAttrs mkDefault;
  inherit (lib.internal) mkBoolOpt mkOpt;

  cfg = config.khanelinix.desktop.addons.gtk;
  default-attrs = mapAttrs (_key: mkDefault);
  nested-default-attrs = mapAttrs (_key: default-attrs);
in
{
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
              accents = [ "blue" ];
              size = "standard";
              variant = "macchiato";
            }) "The package to use for the theme.";
    };
    cursor = {
      name =
        mkOpt str "Catppuccin-Macchiato-Blue-Cursors"
          "The name of the cursor theme to apply.";
      pkg = mkOpt package pkgs.catppuccin-cursors.macchiatoBlue "The package to use for the cursor theme.";
      size = mkOpt int 32 "The size of the cursor.";
    };
    icon = {
      name =
        mkOpt str "breeze-dark"
          "The name of the icon theme to apply.";
      pkg = mkOpt package pkgs.libsForQt5.breeze-icons "The package to use for the icon theme.";
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
      libappindicator-gtk3
    ];

    environment.sessionVariables = {
      XCURSOR_THEME = cfg.cursor.name;
      XCURSOR_SIZE = "${toString cfg.cursor.size}";
      CURSOR_THEME = cfg.cursor.name;
      GTK_THEME = cfg.theme.name;
    };

    services = {
      # needed for GNOME services outside of GNOME Desktop
      dbus.packages = [ pkgs.gcr ];
      udev.packages = with pkgs; [ gnome.gnome-settings-daemon ];
    };

    khanelinix.home = {
      extraOptions = {
        home.pointerCursor = {
          package = cfg.cursor.pkg;
          inherit (cfg.cursor) name;
          inherit (cfg.cursor) size;
          gtk.enable = true;
          x11.enable = true;
        };

        gtk = {
          enable = true;

          theme = {
            inherit (cfg.theme) name;
            package = cfg.theme.pkg;
          };

          cursorTheme = {
            inherit (cfg.cursor) name;
            package = cfg.cursor.pkg;
          };

          iconTheme = {
            inherit (cfg.icon) name;
            package = cfg.icon.pkg;
          };

          font = {
            name = config.khanelinix.system.fonts.default;
          };

          gtk3.extraConfig = {
            "gtk-application-prefer-dark-theme" = 1;
          };

          gtk4.extraConfig = {
            "gtk-application-prefer-dark-theme" = 1;
          };
        };

        dconf = {
          enable = true;

          settings = nested-default-attrs {
            "org/gnome/desktop/interface" = {
              color-scheme = "prefer-dark";
              enable-hot-corners = false;
              font-name = config.khanelinix.system.fonts.default;
              gtk-theme = cfg.theme.name;
              cursor-theme = cfg.cursor.name;
              cursor-size = cfg.cursor.size;
              icon-theme = cfg.icon.name;
            };
          };
        };
      };
    };
  };
}
