{
  config,
  inputs,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) mkDefault mkIf;

  cfg = config.khanelinix.nix;
  homeCfg = config.home-manager.users.${config.khanelinix.user.name} or { };
  anyrunEnabled = homeCfg.khanelinix.programs.graphical.launchers.anyrun.enable or false;
in
{
  imports = [ (lib.getFile "modules/common/nix/default.nix") ];

  config = mkIf cfg.enable {
    documentation = {
      man.cache = {
        enable = mkDefault true;
        # Build the apropos/whatis index via a runtime systemd service instead
        # of at build time, so closure changes don't rebuild the man cache.
        generateAtRuntime = mkDefault true;
      };

      nixos = {
        enable = mkDefault false;

        options = {
          warningsAreErrors = true;
          splitBuild = true;
        };
      };
    };

    # NixOS config options
    # Check corresponding shared imported module
    nix = {
      # Make builds run with low priority so desktop stays responsive
      # "batch" = low CPU priority, "idle" = only use disk when nothing else needs it
      # Change daemonIOSchedClass to "best-effort" if you want faster builds at cost of responsiveness
      daemonCPUSchedPolicy = "batch";
      daemonIOSchedClass = "best-effort";
      daemonIOSchedPriority = 7; # 0-7, higher = lower priority

      gc = {
        automatic = lib.mkForce false;
        dates = "daily";
        options = "--delete-older-than 7d";
        randomizedDelaySec = "45min";
      };

      optimise = {
        automatic = lib.mkForce false;
        dates = [ "04:00" ];
      };

      settings = {
        auto-allocate-uids = true;
        experimental-features = [ "cgroups" ];
        max-free = lib.mkForce (100 * 1024 * 1024 * 1024);
        min-free = lib.mkForce (20 * 1024 * 1024 * 1024);
        system-features = [
          "ca-derivations"
          "uid-range"
        ];
        use-cgroups = true;

        substituters = lib.optionals anyrunEnabled [
          "https://anyrun.cachix.org"
        ];
        trusted-public-keys = lib.optionals anyrunEnabled [
          "anyrun.cachix.org-1:pqBobmOjI7nKlsUMV25u9QHa9btJK65/C8vnO3p346s="
        ];
      };
    };

    services = {
      fast-nix-gc = {
        enable = true;
        package = inputs.fast-nix-gc.packages.${pkgs.stdenv.hostPlatform.system}.default;
        automatic = true;
        dates = "weekly";
        deleteOlderThan = "30d";
        ensureFree = "100G";
        keepRecent = "7d";
        randomizedDelaySec = "45min";
      };

      fast-nix-optimise = {
        enable = true;
        automatic = false;
        dates = [ "04:00" ];
      };
    };
  };
}
