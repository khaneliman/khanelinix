{ options
, config
, lib
, pkgs
, ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.suites.desktop;
in
{
  options.khanelinix.suites.desktop = with types; {
    enable =
      mkBoolOpt false "Whether or not to enable common desktop configuration.";
  };

  config = mkIf cfg.enable {

    environment.systemPackages = with pkgs; [
      authy
      barrier
      bleachbit
      dropbox
      dupeguru
      fontpreview
      keepass
    ];

    khanelinix = {
      desktop = {
        hyprland = enabled;

        addons = {
          gtk = enabled;
          qt = enabled;
          wallpapers = enabled;
        };
      };

      apps = {
        _1password = enabled;
        firefox = enabled;
        gparted = enabled;
        pocketcasts = enabled;
      };
    };
  };
}
