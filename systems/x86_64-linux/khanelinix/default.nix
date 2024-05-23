{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}) enabled;
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

    display-managers = {
      gdm = {
        monitors = ./monitors.xml;
      };

      regreet = {
        hyprlandOutput = builtins.readFile ./hyprlandOutput;
      };
    };

    hardware = {
      audio = enabled;
      bluetooth = enabled;
      cpu.amd = enabled;
      gpu = {
        amd = enabled;
        nvidia = enabled;
      };
      opengl = enabled;

      rgb = {
        openrgb.enable = true;
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

        ssdEnable = true;
      };

      tpm = enabled;
      yubikey = enabled;
    };

    programs = {
      graphical = {
        addons = {
          noisetorch = {
            enable = true;

            threshold = 95;
            device = "alsa_input.usb-Blue_Microphones_Yeti_Stereo_Microphone_LT_191128065321F39907D0_111000-00.analog-stereo";
            deviceUnit = "sys-devices-pci0000:00-0000:00:01.2-0000:02:00.0-0000:03:08.0-0000:08:00.3-usb3-3\x2d2-3\x2d2.1-3\x2d2.1.4-3\x2d2.1.4.3-3\x2d2.1.4.3:1.0-sound-card3-controlC3.device";
          };
        };

        wms = {
          hyprland = {
            enable = true;
          };
        };
      };
    };

    services = {
      avahi = enabled;
      barrier = enabled;
      geoclue = enabled;
      power = enabled;
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
            User ${config.${namespace}.user.name}
            Hostname austinserver.local
        '';
      };

      samba = {
        enable = true;

        shares = {
          public = {
            browseable = true;
            comment = "Home Public folder";
            only-owner-editable = false;
            path = "/home/${config.${namespace}.user.name}/Public/";
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
      pulse-secure = enabled;
      sops = {
        enable = true;
        sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
        defaultSopsFile = lib.snowfall.fs.get-file "secrets/khanelinix/default.yaml";
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
        sqlEnable = true;
      };
    };

    system = {
      boot = {
        enable = true;
        secureBoot = true;
        plymouth = true;
        silentBoot = true;
      };

      fonts = enabled;
      locale = enabled;
      networking = {
        enable = true;
        optimizeTcp = true;
      };
      realtime = enabled;
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

  nix.settings = {
    cores = 24;
    max-jobs = 24;
  };

  networking = {
    defaultGateway = {
      address = "192.168.1.1";
      interface = "enp6s0";
    };

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

  systemd.network.networks = {
    # wired interfaces e.g. ethernet
    "30-network-defaults-wired" = {
      # matchConfig.Name = "en* | eth* | usb*";
      matchConfig.Type = "ether";
      networkConfig = {
        Address = "192.168.1.3/24";
        Gateway = "192.168.1.1";
        # IPv6AcceptRA = true;
        # IPForward = "yes";
        # IPMasquerade = "no";
      };
    };
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.11"; # Did you read the comment?
}
