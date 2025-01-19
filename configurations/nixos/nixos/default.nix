{ khanelinix-lib, ... }:
let
  inherit (khanelinix-lib) enabled;
in
{
  imports = [ ./hardware.nix ];

  programs.sway.extraSessionCommands = # bash
    ''
      WLR_NO_HARDWARE_CURSORS=1
    '';

  khanelinix = {
    nix = enabled;

    archetypes = {
      vm = enabled;
    };

    programs = {
      graphical = {
        apps = {
          _1password = enabled;
        };

        wms = {
          hyprland = {
            enable = true;
          };
        };
      };
    };

    services = {
      printing = enabled;
    };

    security = {
      doas = enabled;
      keyring = enabled;
    };

    system = {
      boot = enabled;
      fonts = enabled;
      locale = enabled;
      networking = enabled;
      time = enabled;
      xkb = enabled;
    };
  };

  services.displayManager.defaultSession = "hyprland";

  nixpkgs.hostPlatform = {
    system = "x86_64-linux";
  };

  system.stateVersion = "21.11"; # Did you read the comment?
}
