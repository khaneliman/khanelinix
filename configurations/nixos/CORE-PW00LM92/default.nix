{ lib, flake, ... }:
let
  inherit (lib) mkForce;
  inherit (flake.inputs.self.lib.khanelinix) enabled disabled;
in
{
  # imports = [ ./hardware.nix ];

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

  nixpkgs.hostPlatform = {
    system = "x86_64-linux";
  };

  system.stateVersion = "23.11"; # Did you read the comment?
}
