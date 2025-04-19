{
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}) enabled;

  cfg = config.${namespace}.user;
in
{
  khanelinix = {
    security = {
      sudo = enabled;
      sops = {
        enable = false;
        sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
        defaultSopsFile = lib.snowfall.fs.get-file "secrets/khanelimac/default.yaml";
      };
    };

    suites = {
      common = enabled;
      development = enabled;
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

  users.users.${cfg.name} = {
    openssh = {
      authorizedKeys.keys = [
        # `khanelinix`
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFuMXeT21L3wnxnuzl0rKuE5+8inPSi8ca/Y3ll4s9pC"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKEilFPAgSUwW3N7PTvdTqjaV2MD3cY2oZGKdaS7ndKB"
        # `khanelimac`
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJAZIwy7nkz8CZYR/ZTSNr+7lRBW2AYy1jw06b44zaID"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINBG8l3jQ2EPLU+BlgtaQZpr4xr97n2buTLAZTxKHSsD"
        # `bruddynix`
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFeLt5cnRnKeil39Ds+CimMJQq/5dln32YqQ+EfYSCvc"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEqCiZgjOmhsBTAFD0LbuwpfeuCnwXwMl2wByxC1UiRt"
      ];
    };
  };

  system = {
    primaryUser = "khaneliman";
    stateVersion = 5;
  };
}
