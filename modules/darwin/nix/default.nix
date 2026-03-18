{
  config,
  lib,

  ...
}:
let
  cfg = config.khanelinix.nix;
in
{
  imports = [ (lib.getFile "modules/common/nix/default.nix") ];

  config = lib.mkIf cfg.enable {
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
          }
        ];
        options = "--delete-older-than 7d";
      };

      # Optimize nix store after cleaning
      optimise.interval = lib.lists.forEach config.nix.gc.interval (e: e // { Hour = e.Hour + 1; });

      # Run builds with low priority to keep the system responsive
      # Equivalent to daemonIOSchedClass/daemonCPUSchedPolicy on NixOS
      daemonProcessType = "Standard";

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
        # FIXME: upstream bug needs to be resolved before fully enabling
        # https://github.com/NixOS/nix/issues/12698
        # TODO: sandbox causes "Bus error: 10" on Darwin 25.2.0, disabling for now.
        sandbox = lib.mkForce false;
      };
    };
  };
}
