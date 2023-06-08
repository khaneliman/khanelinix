{ pkgs
, lib
, config
, ...
}:
with lib;
with lib.internal; {
  imports = [ ./hardware.nix ];

  khanelinix = {
    nix = enabled;

    archetypes = {
      gaming = enabled;
      personal = enabled;
      workstation = enabled;
    };

    apps = {
      _1password = enabled;
      firefox = enabled;
      vscode = enabled;
    };

    cli-apps = { };

    desktop = {
      hyprland = {
        enable = true;

        customConfigFiles = {
          "hypr/displays.conf".source = ./hypr/displays.conf;
          "hypr/environment.conf".source = ./hypr/environment.conf;
        };
        customFiles = {
          ".screenlayout/primary.sh".source = ./.screenlayout/primary.sh;
        };
      };

      addons = {
        # I like to have a convenient place to share wallpapers from
        # even if they're not currently being used.
        wallpapers = enabled;
      };
    };

    suites = {
      desktop = mkForce disabled;
      emulation = enabled;
    };

    tools = {
      k8s = enabled;
      git = enabled;
      node = enabled;
      http = enabled;
      misc = enabled;
      oh-my-posh = enabled;
    };

    hardware = {
      amdgpu = enabled;
      audio = enabled;
      networking = enabled;
      rgb = {
        enable = true;
        ckbNextConfig = ./ckb-next/ckb-next.conf;
      };
      storage = enabled;
      opengl = enabled;
    };

    services = {
      avahi = enabled;
      printing = enabled;
      geoclue = enabled;

      openssh = {
        enable = true;

        authorizedKeys = [
          "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCy8/it2fHl+l0Hoc70HJWh6uyOtlho4gNLUPf2r36AlO2JJIJR/set/pqpPchcOTtROgmkmFDMS7zIG8o2iZbZhSerJ5hxWzSqMUyFEfB/9l8Qh/6gyuDIB8ZtiauV2EpwERtfVAkUOjTi0c20WVdMJNVhINCRZ3AS3zB4LmsBV8cLLPb14SODR5zr9xtj0AzSmb6G7N/Od1k1X2LYIidMFzFmRWrowl56j9HXMSVkQBEkhf7Cp7RMsh/YqgsQkHtUhKAuX+1F87xPeil8RasCso8/aQGr8vb8TUMCNUOO02WLSmcqtKRyB82L74nNHILgL+kQ2cFtppuEqa2j6Tvc62yCKTSdI8uVRHH6t7t84DEInLEXPS0RuR07k9Rlc+01EEmiSCgUHU1jJC8LPlswJrU9hvdyaVkc86J/MIQMSGX+Z98Fo3xNcLQvjpK0NRue773QdCPKdEMhsIJ63EZI7OfcAuhzUvDJOujJ2JVDJgzskne3CLWH37i/19RK0RM= khaneliman@Austins-MacBook-Pro.local"
          "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCsACVsmcfvobSSL8/luWfc6dnkCe7XrFahYkdlHCJzmC2EKw8iq6DLaFyDgFLtWPdpY87FQFGV4j2b9T7nyLyPnWBokWR+SJdi4xTCbCJkkvP6bFqjMJQXkRRps1kVmUF/mdKjd6KNkqbfVfhiTQIl3ITVQQ6bvE9jxZ46o5yqny8a9U/QSaGv87nXmnTC9x5d8NYNE2qHjbZuRupmZVj253qesRC0nbKrlMhLmdtE587URlndERq9UWIenjFvLhRF3Ju3F4hmCylvFvqxdXLy0ElN1pyqQ/RP1DOWSw1w1GwPZF4ysJQKGGTW7aNH/3hjPZT7+euz79b1m+t+Pnz90sw8y+jxBGusRzoQygWcfBulqCaEQl7T4Zp6/8HTgnTw3c7VJ0ke6RYAWANmBX45sOc63+Uu8lxQINckHfbg4agAh8Idmo6tb6AzgrPIanv5avGQ20u+f3diNzgj8qY4YpPZVdBUBAhAVQ/Y0X2Hgc/8R+3gpTZrkN+FEr1NHBE= khaneliman@Austin-Playground"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEpfTVxQKmkAYOrsnroZoTk0LewcBIC4OjlsoJY6QbB0"
        ];

        extraConfig = ''
          Host laptop
            User ${config.khanelinix.user.name}
            Hostname Austins-MacBook-Pro.local

          Host desktop
            User ${config.khanelinix.user.name}
            Hostname 192.168.1.100

          Host server
            User ${config.khanelinix.user.name}
            Hostname 192.168.1.37
        '';
      };

      # TODO: Set up shares
      samba = {
        enable = true;

        shares = {
          public = {
            path = "/home/${config.khanelinix.user.name}/public/";
            comment = "Home Public folder";
            public = true;
            browseable = true;
            only-owner-editable = false;
            read-only = false;
          };

          games = {
            path = "/mnt/games/";
            comment = "Games folder";
            public = true;
            browseable = true;
            only-owner-editable = true;
            read-only = false;
          };
        };
      };
    };

    security = {
      doas = enabled;
      keyring = enabled;
    };

    system = {
      boot = enabled;
      fonts = enabled;
      locale = enabled;
      time = enabled;
      shell = {
        zsh = enabled;
        bash = enabled;
        fish = enabled;
      };
    };

    #   IOMMU Group 24:
    # 	05:00.0 VGA compatible controller [0300]: NVIDIA Corporation GA102 [GeForce RTX 3080] [10de:2206] (rev a1)
    # 	05:00.1 Audio device [0403]: NVIDIA Corporation GA102 High Definition Audio Controller [10de:1aef] (rev a1)
    virtualisation.kvm = {
      enable = true;
      platform = "amd";

      vfioIds = [ "10de:2206" "10de:1aef" ];
      machineUnits = [ "machine-qemu\\x2d4\\x2dwin11\\x2dGPU.scope" ];
    };
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
