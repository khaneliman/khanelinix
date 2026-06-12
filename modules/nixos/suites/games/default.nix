{
  config,
  lib,

  ...
}:
let
  inherit (lib) mkDefault;
  inherit (lib.khanelinix)
    enabled
    mkPackageProfileOption
    suiteProfileIncludes
    ;

  cfg = config.khanelinix.suites.games;
  includes = suiteProfileIncludes config cfg;
in
{
  options.khanelinix.suites.games = {
    enable = lib.mkEnableOption "common games configuration";
    packageProfile = mkPackageProfileOption "Package profile override for game system applications.";
  };

  config = lib.mkIf cfg.enable {
    khanelinix = {
      programs = {
        graphical = {
          addons = {
            gamemode = lib.mkIf (includes "standard") (mkDefault enabled);
            gamescope = lib.mkIf (includes "standard") (mkDefault enabled);
          };

          apps = {
            steam = lib.mkIf (includes "standard") (mkDefault enabled);
          };
        };
      };

      services.flatpak.extraPackages = lib.optionals (includes "maximal") [
        # Sober for Roblox
        {
          appId = "org.vinegarhq.Sober";
          origin = "flathub";
        }
      ];
    };
  };
}
