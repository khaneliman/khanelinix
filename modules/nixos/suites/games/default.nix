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
  userName = config.khanelinix.user.name;
  homeCfg = config.home-manager.users.${userName} or { };
  prismLauncherEnabled = homeCfg.khanelinix.programs.graphical.apps.prismlauncher.enable or false;
  soberEnabled =
    config.khanelinix.services.flatpak.enable
    && builtins.any (
      package:
      (if builtins.isAttrs package then package.appId or null else package) == "org.vinegarhq.Sober"
    ) config.khanelinix.services.flatpak.extraPackages;
in
{
  options.khanelinix.suites.games = {
    enable = lib.mkEnableOption "common games configuration";
    packageProfile = mkPackageProfileOption "Package profile override for game system applications.";
  };

  config = lib.mkIf cfg.enable {
    nix.settings = {
      substituters = [ "https://nix-gaming.cachix.org" ];
      trusted-public-keys = [
        "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
      ];
    };

    khanelinix = {
      hardware.controllers = lib.mkIf (includes "standard") (mkDefault {
        xpadneo.enable = true;
        playstation.enable = true;
        joycon.enable = true;
      });

      programs = {
        graphical = {
          addons = {
            gamemode = lib.mkIf (includes "standard") (mkDefault enabled);
            gamescope = lib.mkIf (includes "standard") (mkDefault enabled);
          };

          apps.steam = lib.mkIf (includes "standard") {
            enable = mkDefault true;
            # Surface the launchers the household uses inside Gaming Mode,
            # where only the Steam library is reachable.
            shortcuts =
              lib.optionals prismLauncherEnabled [
                {
                  name = "Prism Launcher";
                  exe = "/etc/profiles/per-user/${userName}/bin/prismlauncher";
                }
              ]
              ++ lib.optionals soberEnabled [
                {
                  name = "Sober";
                  exe = "/run/current-system/sw/bin/flatpak";
                  launchOptions = "run org.vinegarhq.Sober";
                }
              ];
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
