{ config
, lib
, ...
}:
let
  inherit (lib.internal) enabled;
in
{
  imports = [ ./hardware.nix ];

  khanelinix = {
    nix = enabled;

    archetypes = { };

    hardware = {
      audio = enabled;
      bluetooth = enabled;
      opengl = enabled;

      storage = {
        enable = true;
        zfs = enabled;
      };
    };

    services = {
      avahi = enabled;
      barrier = enabled;
      geoclue = enabled;
      printing = enabled;

      openssh = {
        enable = true;

        authorizedKeys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEpfTVxQKmkAYOrsnroZoTk0LewcBIC4OjlsoJY6QbB0"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINBG8l3jQ2EPLU+BlgtaQZpr4xr97n2buTLAZTxKHSsD"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM7UBwfd7+K0mdkAIb2TE6RzMu6L4wZnG/anuoYqJMPB"
        ];
      };

      # TODO: Set up shares
      samba = {
        enable = true;

        shares = {
          games = {
            browseable = true;
            comment = "Games folder";
            only-owner-editable = true;
            path = "/mnt/games/";
            public = true;
            read-only = false;
          };

          # Application data folder
          appData = {
            browseable = true;
            comment = "Application Data folder";
            onlyOwnerEditable = true;
            path = "/home/${config.khanelinix.user.name}/.config/";
            public = false;
            readOnly = false;
          };

          # Data folder
          data = {
            browseable = true;
            comment = "Data folder";
            onlyOwnerEditable = true;
            path = "/home/${config.khanelinix.user.name}/.local/share/";
            public = false;
            readOnly = false;
          };

          # Virtual Machines folder
          vms = {
            browseable = true;
            comment = "Virtual Machines folder";
            onlyOwnerEditable = true;
            path = "/home/${config.khanelinix.user.name}/vms/";
            public = false;
            readOnly = false;
          };

          # ISO images folder
          isos = {
            browseable = true;
            comment = "ISO Images folder";
            onlyOwnerEditable = true;
            path = "/home/${config.khanelinix.user.name}/isos/";
            public = false;
            readOnly = false;
          };

          # Time Machine backups folder
          timeMachine = {
            browseable = true;
            comment = "Time Machine backups folder";
            onlyOwnerEditable = true;
            path = "/home/${config.khanelinix.user.name}/.timemachine/";
            public = false;
            readOnly = true;
          };
        };
      };
    };

    security = {
      doas = enabled;
      keyring = enabled;
      sops = {
        enable = true;
        sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
        defaultSopsFile = ../../../secrets/khanelilab/default.yaml;
      };
    };

    suites = { };

    system = {
      boot = {
        enable = true;
        secureBoot = true;
        plymouth = true;
      };

      fonts = enabled;
      locale = enabled;
      networking = enabled;
      time = enabled;
    };
  };

  networking = {
    defaultGateway = "192.168.1.1";
    interfaces.enp6s0.ipv4.addresses = [{
      address = "192.168.1.3";
      prefixLength = 24;
    }];
  };

  services.xserver.displayManager.defaultSession = "hyprland";

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.11"; # Did you read the comment?
}
