{
  config,
  lib,

  self,
  inputs,

  ...
}:
let
  inherit (lib) mkDefault mkIf;

  cfg = config.khanelinix.nix;
in
{
  imports = [ (lib.getFile "modules/common/nix/default.nix") ];

  config = mkIf cfg.enable {
    documentation = {
      man.generateCaches = mkDefault true;

      nixos = {
        enable = true;

        options = {
          warningsAreErrors = true;
          splitBuild = true;
        };
      };
    };

    # TODO: This configuration should be in the shared module but environment.etc
    # from shared modules imported via lib.getFile doesn't work properly in flake-parts.
    # The shared module's other configurations (nix.registry, nix.nixPath, etc.) work fine,
    # but environment.etc gets ignored. This is likely due to how lib.getFile imports
    # don't participate in the module system's attribute merging.
    # Fix: Find a way to properly import shared modules so environment.etc works.
    environment.etc = {
      # set channels (backwards compatibility)
      "nix/flake-channels/system".source = self;
      "nix/flake-channels/nixpkgs".source = inputs.nixpkgs;
      "nix/flake-channels/home-manager".source = inputs.home-manager;

      # preserve current flake in /etc
      "nixos".source = self;
    }
    # Create /etc/nix/inputs symlinks for all flake inputs
    // lib.mapAttrs' (
      name: input:
      lib.nameValuePair "nix/inputs/${name}" {
        source = input.outPath or input;
      }
    ) inputs;

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
        dates = "Sun *-*-* 03:00";
      };

      optimise = {
        automatic = true;
        dates = [ "04:00" ];
      };

      settings = {
        auto-allocate-uids = true;
        # bail early on missing cache hits
        connect-timeout = 5;
        experimental-features = [ "cgroups" ];
        keep-going = true;
        use-cgroups = true;

        substituters = [
          "https://anyrun.cachix.org"
          "https://hyprland.cachix.org"
          "https://nix-gaming.cachix.org"
          "https://nixpkgs-wayland.cachix.org"
        ];
        trusted-public-keys = [
          "anyrun.cachix.org-1:pqBobmOjI7nKlsUMV25u9QHa9btJK65/C8vnO3p346s="
          "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
          "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
          "nixpkgs-wayland.cachix.org-1:3lwxaILxMRkVhehr5StQprHdEo4IrE8sRho9R9HOLYA="
        ];
      };
    };
  };
}
