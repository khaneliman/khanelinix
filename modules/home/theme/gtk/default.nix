{
  config,
  lib,
  pkgs,
  # Prefer shared font namespace when HM evaluates standalone.
  # `osConfig` remains optional for compatibility.

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

  config =
    let
      themeDir = "${cfg.theme.package}/share/themes/${cfg.theme.name}";
      gtk4Dir = "${themeDir}/gtk-4.0";

      # Some GTK themes only partially ship GTK4 assets (or omit gtk-dark.css).
      # Build-time checks keep evaluation pure and avoid HM activation failures.
      gtk4Export = pkgs.runCommand "gtk4-theme-${cfg.theme.name}" { } /* Bash */ ''
        mkdir -p "$out"

        if [ -d "${gtk4Dir}/assets" ]; then
          ln -s "${gtk4Dir}/assets" "$out/assets"
        else
          mkdir -p "$out/assets"
        fi

        if [ -f "${gtk4Dir}/gtk.css" ]; then
          ln -s "${gtk4Dir}/gtk.css" "$out/gtk.css"
        else
          : > "$out/gtk.css"
        fi

        if [ -f "${gtk4Dir}/gtk-dark.css" ]; then
          ln -s "${gtk4Dir}/gtk-dark.css" "$out/gtk-dark.css"
        else
          ln -s "$out/gtk.css" "$out/gtk-dark.css"
        fi
      '';
    in
    mkIf (cfg.enable && pkgs.stdenv.hostPlatform.isLinux) {
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
            font-name = "${config.khanelinix.home.fonts.default} ${toString config.khanelinix.home.fonts.size}";
            gtk-theme = cfg.theme.name;
            icon-theme = cfg.icon.name;
          };
        };
      };

      gtk = {
        enable = true;

        font = {
          name = mkDefault config.khanelinix.home.fonts.default;
          size = mkDefault config.khanelinix.home.fonts.size;
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

      # GTK3 theme discovery (some apps still consult ~/.themes).
      home.file.".themes/${cfg.theme.name}".source = themeDir;
      xdg = {
        dataFile."themes/${cfg.theme.name}".source = themeDir;
        # GTK4 CSS/assets live in ~/.config/gtk-4.0.
        configFile = {
          "gtk-4.0/assets".source = "${gtk4Export}/assets";
          "gtk-4.0/gtk.css".source = "${gtk4Export}/gtk.css";
          "gtk-4.0/gtk-dark.css".source = "${gtk4Export}/gtk-dark.css";
        };
        systemDirs.data =
          let
            schema = pkgs.gsettings-desktop-schemas;
          in
          [ "${schema}/share/gsettings-schemas/${schema.name}" ];
      };
    };
}
