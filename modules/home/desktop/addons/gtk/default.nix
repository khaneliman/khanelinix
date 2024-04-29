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
  inherit (lib.internal) mkBoolOpt mkOpt;

  cfg = config.khanelinix.desktop.addons.gtk;
  themeCfg = config.khanelinix.desktop.theme;

  default-attrs = mapAttrs (_key: mkDefault);
  nested-default-attrs = mapAttrs (_key: default-attrs);
in
{
  options.khanelinix.desktop.addons.gtk = {
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
  };

  config = mkIf cfg.enable {
    # TODO: check if this is even needed still
    home.sessionVariables = {
      GTK_THEME = cfg.theme.name;
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

      gtk3.extraConfig = {
        "gtk-application-prefer-dark-theme" = 1;
      };

      gtk4.extraConfig = {
        "gtk-application-prefer-dark-theme" = 1;
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
  };
}
