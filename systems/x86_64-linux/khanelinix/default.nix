{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib.khanelinix) enabled;
  inherit (lib) mkMerge;
in
{
  imports = [
    ./disks.nix
    ./hardware.nix
    ./network.nix
    ./specializations.nix
  ];

  khanelinix = {
    nix = {
      enable = true;
      package = pkgs.lixPackageSets.stable.lix;
      useLix = true;
    };

    archetypes = {
      gaming = enabled;
      personal = enabled;
      workstation = enabled;
    };

    environments = {
      home-network = enabled;
    };

    display-managers = {
      gdm.monitors = ./monitors.xml;
      regreet.hyprlandOutput = builtins.readFile ./hyprlandOutput;
    };

    programs.graphical = {
      addons.noisetorch = {
        enable = false;
        threshold = 95;
        device = "alsa_input.usb-Blue_Microphones_Yeti_Stereo_Microphone_LT_191128065321F39907D0_111000-00.analog-stereo";
        deviceUnit = "sys-devices-pci0000:00-0000:00:01.2-0000:02:00.0-0000:03:08.0-0000:08:00.3-usb3-3\\x2d2-3\\x2d2.1-3\\x2d2.1.4-3\\x2d2.1.4.3-3\\x2d2.1.4.3:1.0-sound-card3-controlC3.device";
      };

      wms = mkMerge [
        { hyprland.enable = true; }
        {
          sway = {
            enable = true;
            withUWSM = true;
          };
        }
      ];
    };

    services = {
      # avahi = enabled;
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
      };

      samba = {
        enable = true;
        shares =
          let
            mkShare =
              {
                sharePath,
                comment,
                readOnly ? false,
                ownerOnly ? false,
              }:
              {
                browseable = true;
                inherit comment;
                path = sharePath;
                only-owner-editable = ownerOnly;
                public = true;
                read-only = readOnly;
              };
          in
          {
            public = mkShare {
              comment = "Home Public folder";
              sharePath = "${config.users.users.${config.khanelinix.user.name}.home}/Public/";
            };

            games = mkShare {
              comment = "Games folder";
              sharePath = "/mnt/games/";
              ownerOnly = true;
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
        defaultSopsFile = lib.getFile "secrets/khanelinix/default.yaml";
      };
    };

    suites.development = {
      enable = true;
      aiEnable = true;
      dockerEnable = true;
      sqlEnable = true;
    };

    system = {
      boot = {
        enable = true;
        secureBoot = true;
        plymouth = true;
        silentBoot = true;
      };

      fonts = enabled;
      networking = {
        enable = true;
        optimizeTcp = true;
      };
      realtime = enabled;
      time = enabled;
    };

    theme = {
      # gtk = enabled;
      # qt = enabled;
      stylix = enabled;
    };
  };

  services = {
    displayManager.defaultSession = "hyprland-uwsm";
  };

  system.stateVersion = "21.11";
}
