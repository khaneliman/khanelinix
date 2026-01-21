{
  config,
  lib,

  self,
  inputs,

  ...
}:
let
  cfg = config.khanelinix.nix;
in
{
  imports = [ (lib.getFile "modules/common/nix/default.nix") ];

  config = lib.mkIf cfg.enable {
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
      "nix-darwin".source = self;
    }
    # Create /etc/nix/inputs symlinks for all flake inputs
    // lib.mapAttrs' (
      name: input:
      lib.nameValuePair "nix/inputs/${name}" {
        source = input.outPath or input;
      }
    ) inputs;

    # Nix-Darwin config options
    # Check corresponding shared imported module
    nix = {
      # Options that aren't supported through nix-darwin
      extraOptions = ''
        # bail early on missing cache hits
        connect-timeout = 10
        keep-going = true
      '';

      gc = {
        interval = [
          {
            Hour = 3;
            Minute = 15;
            Weekday = 1;
          }
        ];
      };

      # Optimize nix store after cleaning
      optimise.interval = lib.lists.forEach config.nix.gc.interval (e: {
        inherit (e) Minute Weekday;
        Hour = e.Hour + 1;
      });

      # Run builds with low priority to keep the system responsive
      # Equivalent to daemonIOSchedClass/daemonCPUSchedPolicy on NixOS
      daemonProcessType = "Adaptive";

      settings = {
        build-users-group = "nixbld";

        extra-sandbox-paths = [
          "/System/Library/Frameworks"
          "/System/Library/PrivateFrameworks"
          "/usr/lib"

          "/private/tmp"
          "/private/var/tmp"
          "/usr/bin/env"
        ];

        # Frequent issues with networking failures on darwin
        # limit number to see if it helps
        http-connections = lib.mkForce 25;

        # FIXME: upstream bug needs to be resolved before fully enabling
        # https://github.com/NixOS/nix/issues/12698
        # TODO: sandbox causes "Bus error: 10" on Darwin 25.2.0, disabling for now.
        sandbox = lib.mkForce false;
      };
    };
  };
}
