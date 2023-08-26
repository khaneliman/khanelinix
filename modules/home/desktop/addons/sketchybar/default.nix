{ options
, config
, lib
, ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.desktop.addons.sketchybar;
in
{
  options.khanelinix.desktop.addons.sketchybar = with types; {
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
