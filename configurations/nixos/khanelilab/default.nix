{
  config,
  root,
  khanelinix-lib,
  ...
}:
let
  inherit (khanelinix-lib) enabled;
in
{
  imports = [
    # TODO:
    # ./disks.nix
    ./hardware.nix
  ];

  khanelinix = {
    nix = enabled;

    hardware = {
      audio = enabled;
      bluetooth = enabled;
      cpu.intel = enabled;
      opengl = enabled;

      storage = {
        enable = true;
        ssdEnable = true;
        zfs = enabled;
      };
    };

    services = {
      # avahi = enabled;
      # TODO: input-leap replace barrier
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
            only-owner-editable = true;
            path = "/home/${config.khanelinix.user.name}/.config/";
            public = false;
            read-only = false;
          };

          # Data folder
          data = {
            browseable = true;
            comment = "Data folder";
            only-owner-editable = true;
            path = "/home/${config.khanelinix.user.name}/.local/share/";
            public = false;
            read-only = false;
          };

          # Virtual Machines folder
          vms = {
            browseable = true;
            comment = "Virtual Machines folder";
            only-owner-editable = true;
            path = "/home/${config.khanelinix.user.name}/vms/";
            public = false;
            read-only = false;
          };

          # ISO images folder
          isos = {
            browseable = true;
            comment = "ISO Images folder";
            only-owner-editable = true;
            path = "/home/${config.khanelinix.user.name}/isos/";
            public = false;
            read-only = false;
          };

          # Time Machine backups folder
          timeMachine = {
            browseable = true;
            comment = "Time Machine backups folder";
            only-owner-editable = true;
            path = "/home/${config.khanelinix.user.name}/.timemachine/";
            public = false;
            read-only = true;
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
        defaultSopsFile = root + "/secrets/khanelilab/default.yaml";
      };
    };

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
    defaultGateway = {
      address = "192.168.1.1";
      interface = "eth0";
    };

    interfaces.eth0.ipv4.addresses = [
      {
        address = "192.168.1.37";
        prefixLength = 24;
      }
    ];
  };

  nixpkgs.hostPlatform = {
    system = "x86_64-linux";
  };

  system.stateVersion = "21.11"; # Did you read the comment?
}
