{
  config,
  lib,
  ...
}:
let
  cfg = config.khanelinix.nix;
in
{
  imports = [ (khanelinix-lib.getFile "modules/shared/nix/default.nix") ];

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

        user = config.khanelinix.user.name;
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

        user = config.khanelinix.user.name;
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

        # FIX: shouldn't disable, but getting sandbox max size errors on darwin
        # darwin-rebuild --rollback on testing changing
        sandbox = lib.mkForce false;
      };
    };
  };
}
