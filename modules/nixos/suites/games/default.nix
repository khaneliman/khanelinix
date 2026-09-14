{
  config,
  lib,
  pkgs,

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

  # Community artwork from SteamGridDB, pinned by hash so the library looks
  # the same on every deploy. Game ids: Minecraft 38365, Roblox 35464.
  sgdb =
    kind: hash: sha256:
    pkgs.fetchurl {
      url = "https://cdn2.steamgriddb.com/${kind}/${hash}";
      inherit sha256;
    };
  minecraftArt = {
    icon =
      sgdb "icon" "5698620bc382e43590e89eefc3097d3e.png"
        "sha256-TyCAvc1A1s2tPQTDKBdgo4EjSNFL+2tBz+v+/zmRsX8=";
    grid =
      sgdb "grid" "a73027901f88055aaa0fd1a9e25d36c7.png"
        "sha256-UZ77kc4lnmFFEY1akV4d1Y/sB773HJSk8LY4bPetZTs=";
    hero =
      sgdb "hero" "47f4b6321e9fd8e8f7326a6adc1a7c1e.png"
        "sha256-AmEY6mchhGyHs/la9TOBIsOqAeHEMlLHs9Nk8OdLyoQ=";
    logo =
      sgdb "logo" "90915208c601cc8c86ad01250ee90c12.png"
        "sha256-ACo+WqxSsGgXSkVAEQFbFq4DZawUklHqWyB7uq06hpA=";
  };
  robloxArt = {
    icon =
      sgdb "icon" "b7f5d38aaa4e8a553f49c085ee06bb15.png"
        "sha256-lyGnXVV7LClO70Lar4rhMFZ7cBj6zjW3HcapkvisW68=";
    grid =
      sgdb "grid" "15c08959e5e7b1930cb81c503058b4c4.png"
        "sha256-3r6Ftw3v5213S6U0YIkOMrSMR0vDSpR4rCbXgNvXN6s=";
    hero =
      sgdb "hero" "1e3b2280c3c02e5e9a89259bdf6e887c.png"
        "sha256-8DazUzgyHn361Jz6HsZ06rdVckgiZdUoMK114TG1WoA=";
    logo =
      sgdb "logo" "05959582fd11fd858d3280739df2b715.png"
        "sha256-ekLP5LDxbBPeJK+vhvJMt6OmMTyzFgQkEefjH9QNUe0=";
  };
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
                  name = "Minecraft";
                  exe = "/etc/profiles/per-user/${userName}/bin/prismlauncher";
                  inherit (minecraftArt) icon;
                  artwork = {
                    inherit (minecraftArt) grid hero logo;
                  };
                }
              ]
              ++ lib.optionals soberEnabled [
                {
                  name = "Roblox";
                  exe = "/run/current-system/sw/bin/flatpak";
                  launchOptions = "run org.vinegarhq.Sober";
                  inherit (robloxArt) icon;
                  artwork = {
                    inherit (robloxArt) grid hero logo;
                  };
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
