{ options
, config
, lib
, pkgs
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt enabled;

  cfg = config.khanelinix.suites.desktop;
in
{
  options.khanelinix.suites.desktop = {
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
