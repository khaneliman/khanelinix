{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkDefault mkIf;

  cfg = config.${namespace}.nix;
in
{
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
        experimental-features = [ "cgroups" ];
        keep-going = true;
        use-cgroups = true;
      };

      # flake-utils-plus
      generateNixPathFromInputs = true;
      generateRegistryFromInputs = true;
      linkInputs = true;
    };
  };
}
