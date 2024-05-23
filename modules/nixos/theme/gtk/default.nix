{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) types mkIf;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;

  cfg = config.${namespace}.theme.gtk;
in
{
  options.${namespace}.theme.gtk = with types; {
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
      sessionVariables = {
        GTK_THEME = cfg.theme.name;
      };
    };

    services = {
      # needed for GNOME services outside of GNOME Desktop
      dbus.packages = [ pkgs.gcr ];
      udev.packages = with pkgs; [ gnome.gnome-settings-daemon ];
    };
  };
}
