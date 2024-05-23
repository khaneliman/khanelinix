{ lib, namespace, ... }:
let
  inherit (lib) mkForce;
  inherit (lib.${namespace}) enabled disabled;
in
{
  imports = [ ./hardware.nix ];

  documentation.man.enable = mkForce true;

  khanelinix = {
    archetypes = {
      wsl = enabled;
    };

    hardware = {
      yubikey = enabled;
    };

    nix = enabled;

    security = {
      # FIX: make gpg work on wsl
      gpg = mkForce disabled;
      sops = {
        enable = true;
        sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
        defaultSopsFile = lib.snowfall.fs.get-file "secrets/CORE/default.yaml";
      };
    };

    suites = {
      common = enabled;
      development = {
        enable = true;
        azureEnable = true;
        dockerEnable = true;
        kubernetesEnable = true;
        nixEnable = true;
        sqlEnable = true;
      };
    };

    theme = {
      gtk = enabled;
      qt = enabled;
    };

    user = {
      name = "nixos";
    };
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?
}
