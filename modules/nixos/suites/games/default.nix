{
  config,
  lib,

  ...
}:
let
  inherit (lib) mkDefault;
  inherit (lib.khanelinix) enabled;

  cfg = config.khanelinix.suites.games;
in
{
  options.khanelinix.suites.games = {
    enable = lib.mkEnableOption "common games configuration";
  };

  config = lib.mkIf cfg.enable {
    khanelinix = {
      programs = {
        graphical = {
          addons = {
            gamemode = mkDefault enabled;
            gamescope = mkDefault enabled;
          };

          apps = {
            steam = mkDefault enabled;
          };
        };
      };

      services.flatpak.extraPackages = [
        # Sober for Roblox
        {
          appId = "org.vinegarhq.Sober";
          origin = "flathub";
        }
      ];
    };
  };
}
