{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.khanelinix.theme.nord;

  qtThemeName =
    if cfg.variant == "darker" then
      "Nordic-Darker"
    else if cfg.variant == "bluish" then
      "Nordic-bluish"
    else
      "Nordic";
in
{
  config = lib.mkIf cfg.enable {
    khanelinix.theme.qt = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
      theme = {
        name = qtThemeName;
        package = pkgs.nordic;
      };
    };
  };
}
