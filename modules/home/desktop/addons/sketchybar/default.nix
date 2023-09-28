{ config
, lib
, options
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt;

  cfg = config.khanelinix.desktop.addons.sketchybar;
in
{
  options.khanelinix.desktop.addons.sketchybar = {
    enable =
      mkBoolOpt false "Whether to enable sketchybar in the desktop environment.";
  };

  config = mkIf cfg.enable {
    xdg.configFile = {
      "sketchybar" = {
        source = lib.cleanSourceWith {
          src = lib.cleanSource ./config/.;
        };

        recursive = true;
      };

      "dynamic-island-sketchybar" = {
        source = lib.cleanSourceWith {
          src = lib.cleanSource ./dynamic-island-sketchybar/.;
        };

        recursive = true;
      };
    };
  };
}
