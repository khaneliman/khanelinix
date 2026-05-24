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
      tailscale = enabled;
    };

    archetypes.home-lab = enabled;

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
