{ lib, ... }:
let
  inherit (lib.khanelinix) enabled;
in
{
  imports = [ ./hardware.nix ];

  programs.sway.extraSessionCommands = /* bash */ ''
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

  services.displayManager.defaultSession = "hyprland-uwsm";
  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?
}
