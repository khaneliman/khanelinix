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
    ./disks.nix
    ./hardware.nix
    ./network.nix
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
      audio = {
        enable = true;
      };
      bluetooth = enabled;
      cpu.amd = enabled;
      gpu = {
        amd = {
          enable = true;
          enableRocmSupport = true;
          enableNvtop = true;
        };
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
          # dedupe = true;

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
            enable = false;

            threshold = 95;
            device = "alsa_input.usb-Blue_Microphones_Yeti_Stereo_Microphone_LT_191128065321F39907D0_111000-00.analog-stereo";
            deviceUnit = "sys-devices-pci0000:00-0000:00:01.2-0000:02:00.0-0000:03:08.0-0000:08:00.3-usb3-3\x2d2-3\x2d2.1-3\x2d2.1.4-3\x2d2.1.4.3-3\x2d2.1.4.3:1.0-sound-card3-controlC3.device";
          };
        };

        wms = {
          hyprland = {
            enable = true;
          };

          sway = {
            enable = true;
          };
        };
      };
    };

    services = {
      avahi = enabled;
      # TODO: input-leap replace barrier
      geoclue = enabled;
      power = enabled;
      printing = enabled;
      rustdesk-server = {
        enable = true;
        relayHosts = [ "khanelinix.local" ];
      };

      snapper = {
        enable = true;

        configs = {
          # Example
          # Don't really store anything worth keeping backups here for
          # Documents = {
          #   ALLOW_USERS = [ "khaneliman" ];
          #   SUBVOLUME = "/home/khaneliman/Documents";
          #   TIMELINE_CLEANUP = true;
          #   TIMELINE_CREATE = true;
          # };
        };
      };

      openssh = {
        enable = true;

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
      sudo-rs = enabled;
      sops = {
        enable = true;
        sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
        defaultSopsFile = lib.snowfall.fs.get-file "secrets/khanelinix/default.yaml";
      };
    };

    suites = {
      development = {
        enable = true;
        dockerEnable = true;
        gameEnable = true;
        kubernetesEnable = true;
        nixEnable = true;
        sqlEnable = true;
        aiEnable = true;
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
    cores = 16;
    max-jobs = 8;
  };

  services = {
    displayManager.defaultSession = "hyprland-uwsm";
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
