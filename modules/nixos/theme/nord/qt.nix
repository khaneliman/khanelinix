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
    khanelinix.theme.qt = {
      theme =
        let
          qtThemeName =
            if cfg.variant == "darker" then
              "Nordic-Darker"
            else if cfg.variant == "bluish" then
              "Nordic-bluish"
            else
              "Nordic";
        in
        {
          name = qtThemeName;
          package = pkgs.nordic;
        };
    };
  };
}
