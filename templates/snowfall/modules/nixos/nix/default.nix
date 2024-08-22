{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkDefault mkIf mkForce;

  cfg = config.${namespace}.nix;
in
{
  imports = [ (lib.snowfall.fs.get-file "modules/shared/nix/default.nix") ];

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

    nix = {
      # make builds run with low priority so my system stays responsive
      daemonCPUSchedPolicy = "batch";
      daemonIOSchedClass = "idle";
      daemonIOSchedPriority = 7;

      gc = {
        dates = "Sun *-*-* 03:00";
      };

      optimise = {
        automatic = true;
        dates = [ "04:00" ];
      };

      settings = {
        # bail early on missing cache hits
        connect-timeout = 5;
        experimental-features = mkForce "cgroups nix-command flakes";
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

      # flake-utils-plus
      generateNixPathFromInputs = true;
      generateRegistryFromInputs = true;
      linkInputs = true;
    };
  };
}
