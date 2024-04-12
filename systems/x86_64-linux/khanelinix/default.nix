{ config, lib, ... }:
let
  inherit (lib.internal) enabled;
in
{
  imports = [
    ./hardware.nix
    ./specializations.nix
  ];

  khanelinix = {
    nix = enabled;

    archetypes = {
      gaming = enabled;
      personal = enabled;
      workstation = enabled;
    };

    desktop = {
      hyprland = {
        enable = true;
      };
    };

    display-managers = {
      gdm = {
        monitors = ./monitors.xml;
      };

      regreet = {
        hyprlandOutput = builtins.readFile ./hyprlandOutput;
      };
    };

    hardware = {
      amdgpu = enabled;
      audio = enabled;
      bluetooth = enabled;
      nvidia = enabled;
      opengl = enabled;

      rgb = {
        enable = true;
        ckbNextConfig = ./ckb-next/ckb-next.conf;
      };

      storage = {
        enable = true;
        btrfs = {
          enable = true;
          autoScrub = true;
          dedupe = true;

          dedupeFilesystems = [
            "nixos"
            "BtrProductive"
          ];

          scrubMounts = [
            "/"
            "/mnt/steam"
          ];
        };
      };
    };

    services = {
      avahi = enabled;
      barrier = enabled;
      geoclue = enabled;
      printing = enabled;

      snapper = {
        enable = true;

        configs = {
          Documents = {
            ALLOW_USERS = [ "khaneliman" ];
            SUBVOLUME = "/home/khaneliman/Documents";
            TIMELINE_CLEANUP = true;
            TIMELINE_CREATE = true;
          };
        };
      };

      openssh = {
        enable = true;

        authorizedKeys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEpfTVxQKmkAYOrsnroZoTk0LewcBIC4OjlsoJY6QbB0"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINBG8l3jQ2EPLU+BlgtaQZpr4xr97n2buTLAZTxKHSsD"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM7UBwfd7+K0mdkAIb2TE6RzMu6L4wZnG/anuoYqJMPB"
        ];

        # TODO: make part of ssh config proper
        extraConfig = ''
          Host server
            User ${config.khanelinix.user.name}
            Hostname austinserver.local
        '';
      };

      # TODO: Set up shares
      samba = {
        enable = true;

        shares = {
          public = {
            browseable = true;
            comment = "Home Public folder";
            only-owner-editable = false;
            path = "/home/${config.khanelinix.user.name}/Public/";
            public = true;
            read-only = false;
          };

          games = {
            browseable = true;
            comment = "Games folder";
            only-owner-editable = true;
            path = "/mnt/games/";
            public = true;
            read-only = false;
          };
        };
      };
    };

    security = {
      # doas = enabled;
      keyring = enabled;
      sops = {
        enable = true;
        sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
        defaultSopsFile = ../../../secrets/khanelinix/default.yaml;
      };
      sudo-rs = enabled;
    };

    suites = {
      development = {
        enable = true;
        dockerEnable = true;
        gameEnable = true;
        kubernetesEnable = true;
        nixEnable = true;
        rustEnable = true;
        sqlEnable = true;
      };

      emulation = {
        enable = true;
        # retroarchFull = true;
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

    #   IOMMU Group 24:
    # 	05:00.0 VGA compatible controller [0300]: NVIDIA Corporation GA102 [GeForce RTX 3080] [10de:2206] (rev a1)
    # 	05:00.1 Audio device [0403]: NVIDIA Corporation GA102 High Definition Audio Controller [10de:1aef] (rev a1)
    virtualisation.kvm = {
      enable = true;
      machineUnits = [ "machine-qemu\\x2d4\\x2dwin11\\x2dGPU.scope" ];
      platform = "amd";
      vfioIds = [
        "10de:2206"
        "10de:1aef"
      ];
    };
  };

  networking = {
    defaultGateway = "192.168.1.1";
    interfaces.enp6s0.ipv4.addresses = [
      {
        address = "192.168.1.3";
        prefixLength = 24;
      }
    ];
  };

  services = {
    displayManager.defaultSession = "hyprland";
    mpd = {
      musicDirectory = "nfs://austinserver.local/mnt/user/data/media/music";
    };
    rpcbind.enable = true; # needed for NFS
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.11"; # Did you read the comment?
}
