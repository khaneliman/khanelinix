{ options
, config
, lib
, pkgs
, ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.desktop.addons.gtk;
  gdmCfg = config.services.xserver.displayManager.gdm;
  default-attrs = mapAttrs (key: mkDefault);
  nested-default-attrs = mapAttrs (key: default-attrs);
in
{
  options.khanelinix.desktop.addons.gtk = with types; {
    enable = mkBoolOpt false "Whether to customize GTK and apply themes.";
    theme = {
      name =
        mkOpt str "Catppuccin-Macchiato-Standard-Blue-Dark"
          "The name of the GTK theme to apply.";
      pkg = mkOpt package
        (pkgs.catppuccin-gtk.override
          ({
            accents = [ "blue" ];
            size = "standard";
            variant = "macchiato";
          })) "The package to use for the theme.";
    };
    cursor = {
      name =
        mkOpt str "Catppuccin-Macchiato-Blue-Cursors"
          "The name of the cursor theme to apply.";
      pkg = mkOpt package pkgs.catppuccin-cursors.macchiatoBlue "The package to use for the cursor theme.";
    };
    icon = {
      name =
        mkOpt str "Papirus"
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

    services =
      {
        # needed for GNOME services outside of GNOME Desktop
        dbus.packages = [ pkgs.gcr ];
        udev.packages = with pkgs; [ gnome.gnome-settings-daemon ];
      };

    khanelinix.home = {
      file = {
        ".themes/Catppuccin-Dark".source = cfg.theme.pkg.outPath + "/share/themes/${cfg.theme.name}/";
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
            # Index.theme is named Catppuccin-Dark for some reason...
            name = "Catppuccin-Dark";
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

          settings =
            let
              user = config.users.users.${config.khanelinix.user.name};
            in
            nested-default-attrs {
              "org/gnome/desktop/interface" = {
                color-scheme = "prefer-dark";
                enable-hot-corners = false;
                font-theme = config.khanelinix.system.fonts.default;
              };
            };
        };
      };
    };


    # @NOTE(jakehamilton): In order to set the cursor theme in GDM we have to specify it in the
    # dconf profile. However, the NixOS module doesn't provide an easy way to do this so the relevant
    # parts have been extracted from:
    # https://github.com/NixOS/nixpkgs/blob/96e18717904dfedcd884541e5a92bf9ff632cf39/nixos/modules/services/x11/display-managers/gdm.nix
    #
    # @NOTE(jakehamilton): The GTK and icon themes don't seem to affect recent GDM versions. I've
    # left them here as reference for the future.
    programs.dconf.profiles = {
      gdm =
        let
          customDconf = pkgs.writeTextFile {
            name = "gdm-dconf";
            destination = "/dconf/gdm-custom";
            text = ''
              ${optionalString (!gdmCfg.autoSuspend) ''
                [org/gnome/settings-daemon/plugins/power]
                sleep-inactive-ac-type='nothing'
                sleep-inactive-battery-type='nothing'
                sleep-inactive-ac-timeout=0
                sleep-inactive-battery-timeout=0
              ''}

              [org/gnome/desktop/interface]
              gtk-theme='${cfg.theme.name}'
              cursor-theme='${cfg.cursor.name}'
              icon-theme='${cfg.icon.name}'
              font-theme='${config.khanelinix.system.fonts.default}'
              color-scheme='prefer-dark'
              enable-hot-corners=false
              enable-animations=true
            '';
          };

          customDconfDb = pkgs.stdenv.mkDerivation {
            name = "gdm-dconf-db";
            buildCommand = ''
              ${pkgs.dconf}/bin/dconf compile $out ${customDconf}/dconf
            '';
          };
        in
        mkForce (
          pkgs.stdenv.mkDerivation {
            name = "dconf-gdm-profile";
            buildCommand = ''
              # Check that the GDM profile starts with what we expect.
              if [ $(head -n 1 ${pkgs.gnome.gdm}/share/dconf/profile/gdm) != "user-db:user" ]; then
                echo "GDM dconf profile changed, please update gtk/default.nix"
                exit 1
              fi
              # Insert our custom DB behind it.
              sed '2ifile-db:${customDconfDb}' ${pkgs.gnome.gdm}/share/dconf/profile/gdm > $out
            '';
          }
        );
    };
  };
}
