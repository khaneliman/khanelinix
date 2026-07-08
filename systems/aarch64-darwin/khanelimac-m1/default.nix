{
  lib,
  config,

  ...
}:
let
  inherit (lib.khanelinix) enabled;

  cfg = config.khanelinix.user;
  hosts = import (lib.getFile "modules/common/programs/terminal/tools/ssh/hosts.nix");
  hostUserPublicKeys = lib.mapAttrsToList (_: host: host.userPublicKey) (
    lib.filterAttrs (_: host: host ? userPublicKey) hosts
  );
in
{
  khanelinix = {
    environments = {
      home-network = {
        enable = true;
        enableNFSMounts = false;
      };
    };

    security = {
      sudo = enabled;
      sops = {
        enable = false;
        sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
        defaultSopsFile = lib.getFile "secrets/khanelimac/default.yaml";
      };
    };

    suites = {
      common = enabled;
      networking = enabled;
    };

    tools = {
      homebrew.enable = false;
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
    cores = 10;
    max-jobs = 3;
  };

  khanelinix.system.networking.pruneStaleLocalNetworkPermissions = false;
  khanelinix.system.tcc.pruneStaleAccessibilityPermissions = false;

  users.users.${cfg.name} = {
    openssh = {
      authorizedKeys.keys = hostUserPublicKeys ++ [
        # `austinserver hermes`
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG1MjYs1zQ6dxFyNwUTR/1K0QI65nuJ6h1xINWnQEUdy hermes-agent@austinserver"
      ];
    };
  };

  system = {
    primaryUser = "khaneliman";
    stateVersion = 7;
  };

  system.defaults.universalaccess.reduceMotion = lib.mkForce null;
}
