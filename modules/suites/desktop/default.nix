{
  options,
  config,
  lib,
  ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.suites.desktop;
in {
  options.khanelinix.suites.desktop = with types; {
    enable =
      mkBoolOpt false "Whether or not to enable common desktop configuration.";
  };

  config = mkIf cfg.enable {
    khanelinix = {
      desktop = {
        gnome = enabled;

        addons = {
          wallpapers = enabled;
          qt = enabled;
        };
      };

      apps = {
        _1password = enabled;
        firefox = enabled;
        gparted = enabled;
        pocketcasts = enabled;
        vlc = enabled;
      };
    };
  };
}
