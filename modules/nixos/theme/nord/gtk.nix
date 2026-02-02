{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.khanelinix.theme.nord;
in
{
  config = lib.mkIf cfg.enable {
    khanelinix.theme.gtk = {
      theme =
        let
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
          name = gtkThemeName;
          package = pkgs.nordic;
        };
    };
  };
}
