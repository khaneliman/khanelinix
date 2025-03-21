{
  config,
  lib,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.nix;
in
{
  imports = [ (lib.snowfall.fs.get-file "modules/shared/nix/default.nix") ];

  config = lib.mkIf cfg.enable {
    nix = {
      # Options that aren't supported through nix-darwin
      extraOptions = ''
        # bail early on missing cache hits
        connect-timeout = 10
        keep-going = true
      '';

      gc = {
        interval = {
          Day = 7;
          Hour = 3;
        };
      };

      linux-builder = {
        # enable = true;
        ephemeral = true;
        maxJobs = 4;
        speedFactor = 15;
        supportedFeatures = [
          "big-parallel"
          "nixos-test"
        ];
        config = {
          virtualisation.darwin-builder.memorySize = 8 * 1024;
          virtualisation.cores = 8;
        };
      };

      optimise = {
        interval = {
          Day = 7;
          Hour = 4;
        };
      };

      # NOTE: not sure if i saw any benefits changing this
      # daemonProcessType = "Adaptive";

      settings = {
        build-users-group = "nixbld";

        extra-sandbox-paths = [
          "/System/Library/Frameworks"
          "/System/Library/PrivateFrameworks"
          "/usr/lib"
          "/private/tmp"
          "/private/var/tmp"
          "/usr/bin/env"
          # https://github.com/NixOS/nix/issues/4119
          "/nix/store"
        ];

        # Frequent issues with networking failures on darwin
        # limit number to see if it helps
        http-connections = lib.mkForce 25;

        # FIXME: upstream bug needs to be resolved before fully enabling
        # https://github.com/NixOS/nix/issues/12698
        sandbox = lib.mkForce "relaxed";
      };
    };
  };
}
