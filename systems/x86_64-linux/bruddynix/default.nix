{
  config,
  inputs,
  lib,
  ...
}:
let
  inherit (lib.khanelinix) enabled;
in
{
  imports = [
    inputs.jovian.nixosModules.default
    ./disks.nix
    ./hardware.nix
    ./network.nix
    # ./specializations.nix
  ];

  khanelinix = {
    nix = enabled;

    archetypes = {
      gaming = enabled;
      personal = enabled;
    };

    environments = {
      home-network = enabled;
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
          plasma = {
            enable = true;
          };
        };
      };
    };

    services = {
      avahi = enabled;
      geoclue = enabled;
      power = enabled;
      printing = enabled;

      openssh = {
        enable = true;
      };
    };

    security = {
      keyring = enabled;
      sudo-rs = enabled;
      # sops = {
      #   enable = true;
      #   sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
      #   defaultSopsFile = lib.getFile "secrets/bruddynix/default.yaml";
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
        # Steam Deck UI first-time setup requires NetworkManager
        manager = "networkmanager";
      };
      time = enabled;
    };

    theme = {
      # gtk = enabled;
      # qt = enabled;
      catppuccin = enabled;
      stylix = enabled;
    };

    user.name = "bruddy";
  };

  # Home Manager installs the same style without changing the package closure.
  stylix.targets.gtksourceview.enable = false;

  services.displayManager.defaultSession = "gamescope-wayland";
  services.flatpak.update.onActivation = true;

  environment.variables =
    lib.mkIf config.khanelinix.programs.graphical.desktop-environment.gnome.enable
      {
        # Fix black bars in gnome
        GSK_RENDERER = "ngl";
        # Fix mouse pointer in gnome
        NO_POINTER_VIEWPORT = "1";
      };

  # Steam Deck-style Gaming Mode as an optional SDDM session (no auto-launch)
  jovian.steam = {
    enable = true;
    user = "bruddy";
    # Only takes effect with autoStart; re-enable together if switching to console mode
    # desktopSession = "plasma";
  };

  nix.settings = {
    cores = 8;
    max-jobs = 8;
  };

  system.stateVersion = "26.05";
}
