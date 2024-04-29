{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) types mkIf;
  inherit (lib.internal) mkBoolOpt mkOpt;

  cfg = config.khanelinix.desktop.addons.gtk;
in
{
  options.khanelinix.desktop.addons.gtk = with types; {
    enable = mkBoolOpt false "Whether to customize GTK and apply themes.";

    theme = {
      name = mkOpt str "Catppuccin-Macchiato-Standard-Blue-Dark" "The name of the GTK theme to apply.";
      package = mkOpt package (pkgs.catppuccin-gtk.override {
        accents = [ "blue" ];
        size = "standard";
        variant = "macchiato";
      }) "The package to use for the theme.";
    };
  };

  config = mkIf cfg.enable {
    environment = {
      # TODO: check if this is even needed still
      sessionVariables = {
        GTK_THEME = cfg.theme.name;
      };

      systemPackages = with pkgs; [
        dconf # required explicitly with noXlibs
        glib
        gsettings-desktop-schemas
        gtk3.out # for gtk-launch
        libappindicator-gtk3
      ];
    };

    services = {
      # needed for GNOME services outside of GNOME Desktop
      dbus.packages = [ pkgs.gcr ];
      udev.packages = with pkgs; [ gnome.gnome-settings-daemon ];
    };
  };
}
