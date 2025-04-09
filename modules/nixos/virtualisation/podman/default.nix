{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.${namespace}.virtualisation.podman;
in
{
  options.${namespace}.virtualisation.podman = {
    enable = lib.mkEnableOption "podman";
  };

  config = mkIf cfg.enable {
    # NixOS 22.05 moved NixOS Containers to a new state directory and the old
    # directory is taken over by OCI Containers (eg. podman). For systems with
    # system.stateVersion < 22.05, it is not possible to have both enabled.
    # This option disables NixOS Containers, leaving OCI Containers available.
    boot.enableContainers = false;

    environment.systemPackages = with pkgs; [
      podman-compose
      podman-desktop
    ];

    khanelinix = {
      user = {
        extraGroups = [
          "docker"
          "podman"
        ];
      };

      home.extraOptions = {
        home.shellAliases = {
          "docker-compose" = "podman-compose";
        };
      };
    };

    virtualisation = {
      podman = {
        inherit (cfg) enable;

        # prune images and containers periodically
        autoPrune = {
          enable = true;
          flags = [ "--all" ];
          dates = "weekly";
        };

        defaultNetwork.settings.dns_enabled = true;
        dockerCompat = true;
        dockerSocket.enable = true;
      };
    };
  };
}
