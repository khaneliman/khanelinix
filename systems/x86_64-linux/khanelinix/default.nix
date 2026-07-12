{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib.khanelinix) enabled;
  inherit (lib) mkForce mkMerge;
in
{
  imports = [
    ./disks.nix
    ./hardware.nix
    ./network.nix
    ./specializations.nix
  ];

  khanelinix = {
    packageProfile = "standard";

    nix = {
      enable = true;
      # useLix = true;
    };

    archetypes = {
      gaming = enabled;
      personal = enabled;
      workstation = enabled;
    };

    environments = {
      home-network = enabled;
    };

    hardware.keyboards.advantage360 = enabled;

    display-managers = {
      gdm.monitors = ./monitors.xml;
      regreet.hyprlandOutput = builtins.readFile ./hyprlandOutput;
    };

    programs.graphical = {
      addons = {
        gamemode.gpuDevice = 1; # AMD GPU is on card1

        noisetorch = {
          enable = false;
          threshold = 95;
          device = "alsa_input.usb-Blue_Microphones_Yeti_Stereo_Microphone_LT_191128065321F39907D0_111000-00.analog-stereo";
          deviceUnit = "sys-devices-pci0000:00-0000:00:01.2-0000:02:00.0-0000:03:08.0-0000:08:00.3-usb3-3\\x2d2-3\\x2d2.1-3\\x2d2.1.4-3\\x2d2.1.4.3-3\\x2d2.1.4.3:1.0-sound-card3-controlC3.device";
        };
      };

      apps.citrix-workspace = {
        enable = true;
        usbRedirection.enable = true;
      };

      wms = mkMerge [
        {
          hyprland = {
            enable = true;
            gamemode.vrr.enable = true; # Odyssey G9 (DP-1) supports VRR
          };
          niri = {
            enable = true;
            package = pkgs.niri-unstable;
          };
        }
        {
          sway.enable = true;
        }
      ];
    };

    services = {
      avahi = enabled;
      geoclue = enabled;
      power = enabled;
      printing = enabled;

      tailscale = {
        enable = true;
      };

      sunshine = {
        enable = true;
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
        loader = "limine";
        secureBoot = true;
        plymouth = true;
        silentBoot = true;
        limine.resolution = "3840x2160x32";
      };

      fonts = enabled;
      networking.enable = true;
      time = enabled;
    };

    theme = {
      # gtk = enabled;
      # qt = enabled;
      stylix = {
        enable = true;
        theme = "tokyo-night-dark";
      };
      tokyonight = enabled;
    };
  };

  sops.secrets."khanelinix_khaneliman_ssh_key" = {
    sopsFile = lib.getFile "secrets/khanelinix/khaneliman/default.yaml";
  };

  programs.hyprland.withUWSM = false;

  services = {
    displayManager.defaultSession = "hyprland";
    irqbalance.enable = mkForce false;
    sunshine = {
      settings = {
        sunshine_name = "khanelinix";
        capture = "kms";
        encoder = "vaapi";
        adapter_name = "/dev/dri/by-path/pci-0000:0c:00.0-render";
        output_name = 1;
        audio_sink = "alsa_output.pci-0000_0e_00.4.analog-stereo";
        hevc_mode = 3;
        av1_mode = 3;
        global_prep_cmd = builtins.toJSON [
          {
            do = ''if command -v swaymsg >/dev/null 2>&1; then swaymsg "output * dpms on"; fi; if command -v hyprctl >/dev/null 2>&1; then hyprctl dispatch 'hl.dsp.dpms("on")'; fi'';
            undo = ''if command -v swaymsg >/dev/null 2>&1; then swaymsg "output * dpms off"; fi; if command -v hyprctl >/dev/null 2>&1; then hyprctl dispatch 'hl.dsp.dpms("off")'; fi'';
          }
        ];
      };
    };
  };

  # Keep EFI usage predictable when specialisations multiply boot artifacts.
  boot.loader.systemd-boot.configurationLimit = mkForce 10;

  # Dev workstation: include developer/library man pages (man 2/3, devman outputs).
  documentation.dev.enable = true;

  system.stateVersion = "26.05";
}
