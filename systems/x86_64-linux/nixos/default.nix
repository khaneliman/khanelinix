{ lib, ... }:
let
  inherit (lib.internal) enabled;
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

    apps = {
      _1password = enabled;
      firefox = enabled;
      # vscode = enabled;
    };

    desktop = {
      hyprland = {
        enable = true;
      };
    };

    services = {
      printing = enabled;
    };

    security = {
      doas = enabled;
      keyring = enabled;
      sops = {
        enable = true;
        sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
        defaultSopsFile = ../../../secrets/nixos/default.yaml;
      };
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
  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.11"; # Did you read the comment?
}
