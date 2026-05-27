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
      rustdesk-server = enabled;
      tailscale = {
        enable = true;
        advertiseExitNode = true;
        advertiseRoutes = [ "192.168.4.0/24" ];
        ssh.enable = true;
      };
      hermes-agent = {
        enable = true;
        # TODO: provide a secrets-backed env file and model defaults before first use.
        # environmentFiles = [ config.sops.secrets."hermes-env".path ];
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
  };

  system.stateVersion = "25.11";
}
