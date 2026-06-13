{
  config,
  lib,

  ...
}:
let
  inherit (lib.khanelinix) enabled;
  magicDnsSuffix = "taild8431e.ts.net";
in
{
  imports = [
    # TODO: re-enable disk partition module when target layout is finalized
    # ./disks.nix
    ./hardware.nix
    ./networking.nix
    ./storage.nix
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
      avahi = enabled;
      geoclue = enabled;
      printing = enabled;
      openssh = enabled;
      sunshine = enabled;
      tailscale = {
        enable = true;
        advertiseExitNode = true;
        advertiseRoutes = [ "192.168.4.0/24" ];
        ssh.enable = true;
      };
      hermes-agent = {
        enable = true;
        stateDir = "/mnt/user/appdata/hermes-agent";
        environmentFiles = [ config.sops.secrets."hermes-agent/env".path ];
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
      media-server = {
        enable = true;
        appdataDir = "/mnt/user/appdata";
        cacheAppdataDir = "/mnt/pool/appdata";
        mediaDir = "/mnt/user/data/media";
        dataDir = "/mnt/user/data";
      };
      nas = enabled;
      observability = {
        enable = true;
        cacheAppdataDir = "/mnt/pool/appdata";
      };
      security = {
        enable = true;
        cacheAppdataDir = "/mnt/pool/appdata";
      };
      self-hosted = {
        enable = true;
        appdataDir = "/mnt/user/appdata";
        dataDir = "/mnt/user/data";
      };
    };

    services.home-assistant = {
      enable = true;
      configDir = "/mnt/pool/appdata/home-assistant";
    };

    virtualisation = {
      kvm = {
        enable = true;
        platform = "intel";
      };
      podman = enabled;
    };
  };

  sops.secrets = lib.mkIf config.khanelinix.security.sops.enable {
    "cloudflared/khanelimancom.json" = {
      key = "cloudflared_json";
      path = "/run/secrets/cloudflared/khanelimancom.json";
    };

    "hermes-agent/env" = {
      mode = "0400";
      owner = config.services.hermes-agent.user;
      group = config.services.hermes-agent.group;
      restartUnits = [ "hermes-agent.service" ];
    };

    "hermes-agent/ssh-key" = {
      mode = "0400";
      owner = config.services.hermes-agent.user;
      group = config.services.hermes-agent.group;
      restartUnits = [ "hermes-agent.service" ];
    };
  };

  home-manager.users.${config.services.hermes-agent.user} = {
    home = {
      username = config.services.hermes-agent.user;
      homeDirectory = config.services.hermes-agent.stateDir;
      stateVersion = config.system.stateVersion;
    };

    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;

      settings = {
        "*" = {
          AddKeysToAgent = false;
          ForwardAgent = false;
          ServerAliveInterval = 30;
          ServerAliveCountMax = 2;
          StreamLocalBindUnlink = true;
          ConnectTimeout = 5;
          UserKnownHostsFile = "${config.services.hermes-agent.stateDir}/.ssh/known_hosts";
        };

        "khanelinix khanelinix-ts" = {
          HostName = "khanelinix.${magicDnsSuffix}";
          User = config.khanelinix.user.name;
          Port = 22;
          IdentityFile = config.sops.secrets."hermes-agent/ssh-key".path;
          IdentitiesOnly = true;
          BatchMode = true;
          StrictHostKeyChecking = "accept-new";
        };

        "khanelimac khanelimac-ts" = {
          HostName = "khanelimac.${magicDnsSuffix}";
          User = config.khanelinix.user.name;
          Port = 22;
          IdentityFile = config.sops.secrets."hermes-agent/ssh-key".path;
          IdentitiesOnly = true;
          BatchMode = true;
          StrictHostKeyChecking = "accept-new";
        };
      };
    };
  };

  system.stateVersion = "26.05";
}
