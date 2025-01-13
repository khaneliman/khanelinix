{
  config,
  lib,
  ...
}:
let
  inherit (lib.khanelinix) enabled;
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
    };

    display-managers = {
      gdm = {
        defaultSession = "gnome";
      };
    };

    hardware = {
      audio = {
        enable = true;
      };

      bluetooth = enabled;
      cpu.amd = enabled;
      gpu.amd = enabled;
      opengl = enabled;
      rgb.openrgb.enable = true;

      storage = {
        enable = true;
        ssdEnable = true;
      };

      tpm = enabled;
    };

    programs = {
      graphical = {
        desktop-environment = {
          gnome = {
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

      openssh = {
        enable = true;

        authorizedKeys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEpfTVxQKmkAYOrsnroZoTk0LewcBIC4OjlsoJY6QbB0"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINBG8l3jQ2EPLU+BlgtaQZpr4xr97n2buTLAZTxKHSsD"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM7UBwfd7+K0mdkAIb2TE6RzMu6L4wZnG/anuoYqJMPB"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJAZIwy7nkz8CZYR/ZTSNr+7lRBW2AYy1jw06b44zaID"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFuMXeT21L3wnxnuzl0rKuE5+8inPSi8ca/Y3ll4s9pC"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKEilFPAgSUwW3N7PTvdTqjaV2MD3cY2oZGKdaS7ndKB"
        ];

        # TODO: make part of ssh config proper
        extraConfig = ''
          Host server
            User ${config.khanelinix.user.name}
            Hostname austinserver.local
        '';
      };
    };

    security = {
      keyring = enabled;
      sudo-rs = enabled;
      # sops = {
      #   enable = true;
      #   sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
      #   defaultSopsFile = root +  "secrets/bruddynix/default.yaml";
      # };
    };

    system = {
      boot = {
        enable = true;
        # TODO: configure
        # secureBoot = true;
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

    user.name = "bruddy";
  };

  environment.variables = {
    # Fix black bars in gnome
    GSK_RENDERER = "ngl";
    # Fix mouse pointer in gnome
    NO_POINTER_VIEWPORT = "1";
  };

  nixpkgs.hostPlatform = {
    system = "x86_64-linux";
  };

  nix.settings = {
    cores = 8;
    max-jobs = 8;
  };

  services = {
    mpd = {
      musicDirectory = "nfs://austinserver.local/mnt/user/data/media/music";
    };
    rpcbind.enable = true; # needed for NFS
  };

  system.stateVersion = "24.11";
}
