{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.khanelinix.theme.nord;

  gtkThemeName =
    if cfg.variant == "darker" then
      "Nordic-darker"
    else if cfg.variant == "bluish" then
      "Nordic-bluish-accent"
    else if cfg.variant == "polar" then
      "Nordic-Polar"
    else
      "Nordic";
in
{
  config = lib.mkIf cfg.enable {
    khanelinix.theme.gtk = {
      cursor = {
        name = "Nordzy-cursors";
        package = pkgs.nordzy-cursor-theme;
        size = 32;
      };

      icon = {
        name = "Nordzy-dark";
        package = pkgs.nordzy-icon-theme;
      };

      theme = {
        name = gtkThemeName;
        package = pkgs.nordic;
      };
    };
  };
}
