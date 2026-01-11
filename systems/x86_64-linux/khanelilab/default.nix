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
      geoclue = enabled;
      printing = enabled;
      openssh = enabled;

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
            path = "${config.users.users.${config.khanelinix.user.name}.home}/.config/";
            public = false;
            read-only = false;
          };

          # Data folder
          data = {
            browseable = true;
            comment = "Data folder";
            only-owner-editable = true;
            path = "${config.users.users.${config.khanelinix.user.name}.home}/.local/share/";
            public = false;
            read-only = false;
          };

          # Virtual Machines folder
          vms = {
            browseable = true;
            comment = "Virtual Machines folder";
            only-owner-editable = true;
            path = "${config.users.users.${config.khanelinix.user.name}.home}/vms/";
            public = false;
            read-only = false;
          };

          # ISO images folder
          isos = {
            browseable = true;
            comment = "ISO Images folder";
            only-owner-editable = true;
            path = "${config.users.users.${config.khanelinix.user.name}.home}/isos/";
            public = false;
            read-only = false;
          };

          # Time Machine backups folder
          timeMachine = {
            browseable = true;
            comment = "Time Machine backups folder";
            only-owner-editable = true;
            path = "${config.users.users.${config.khanelinix.user.name}.home}/.timemachine/";
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
        defaultSopsFile = lib.getFile "secrets/khanelilab/default.yaml";
      };
    };

    system = {
      boot = {
        enable = true;
        secureBoot = true;
      };

      fonts = enabled;
      networking = enabled;
      time = enabled;
    };

    suites = {
      common = enabled;
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

  system.stateVersion = "25.05";
}
