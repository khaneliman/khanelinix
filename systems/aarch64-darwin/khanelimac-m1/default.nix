{
  lib,
  config,

  ...
}:
let
  inherit (lib.khanelinix) enabled;

  cfg = config.khanelinix.user;
  hosts = import (lib.getFile "systems/fleet-ssh-hosts.nix");
  hostUserPublicKeys = lib.mapAttrsToList (_: host: host.userPublicKey) (
    lib.filterAttrs (_: host: host ? userPublicKey) hosts
  );
in
{
  khanelinix = {
    archetypes.build-host = enabled;

    environments = {
      home-network = {
        enable = true;
        enableNFSMounts = false;
      };
    };

    security = {
      sudo = enabled;
      sops = {
        enable = true;
        sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
        defaultSopsFile = lib.getFile "secrets/khanelimac/default.yaml";
      };
    };
  };

  networking = {
    computerName = "Austins MacBook Pro Build Machine";
    hostName = "khanelimac-m1";
    localHostName = "khanelimac-m1";

    knownNetworkServices = [
      "ThinkPad TBT 3 Dock"
      "Wi-Fi"
      "Thunderbolt Bridge"
    ];

    wakeOnLan = enabled;
  };

  nix.settings = {
    cores = 5;
    max-jobs = 2;
  };

  khanelinix.system.tcc.pruneStaleAccessibilityPermissions = false;

  users.users.${cfg.name} = {
    openssh = {
      authorizedKeys.keys = hostUserPublicKeys;
    };
  };

  system = {
    primaryUser = "khaneliman";
    stateVersion = 7;
  };

  system.defaults.universalaccess.reduceMotion = lib.mkForce null;

  sops.secrets = {
    # Remote-builder SSH identity referenced by nix.buildMachines.
    "khanelimac_khaneliman_ssh_key".sopsFile = lib.getFile "secrets/khanelimac/khaneliman/default.yaml";
  };
}
