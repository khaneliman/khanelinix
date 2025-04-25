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
