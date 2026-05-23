{
  config,
  inputs,
  lib,
  pkgs,

  ...
}:
let
  cfg = config.khanelinix.nix;
  fastNixGc = inputs.fast-nix-gc.packages.${pkgs.stdenv.hostPlatform.system}.default;
  sketchybar = "/etc/profiles/per-user/${config.khanelinix.user.name}/bin/sketchybar";
  triggerSketchybarNixUpdate = ''
    if [ -x ${lib.escapeShellArg sketchybar} ]; then
      /bin/launchctl asuser "$(/usr/bin/id -u ${lib.escapeShellArg config.khanelinix.user.name})" \
        /usr/bin/sudo -u ${lib.escapeShellArg config.khanelinix.user.name} \
        ${lib.escapeShellArg sketchybar} --trigger nix_update >/dev/null 2>&1 || true
    fi
  '';
  wrapNixJob = command: ''
    ${triggerSketchybarNixUpdate}
    ${command}
    status=$?
    ${triggerSketchybarNixUpdate}
    exit $status
  '';
in
{
  imports = [ (lib.getFile "modules/common/nix/default.nix") ];

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      (lib.mkIf config.nix.gc.automatic {
        # Only override the GC daemon command when the daemon is actually enabled.
        launchd.daemons.nix-gc.command = lib.mkForce (
          wrapNixJob "/usr/bin/caffeinate -i -s ${fastNixGc}/bin/fast-nix-gc ${config.nix.gc.options}"
        );
      })
      {
        # Wrap optimise in caffeinate to prevent sleep while running.
        launchd.daemons.nix-optimise.command = lib.mkForce (
          wrapNixJob "/usr/bin/caffeinate -i -s ${fastNixGc}/bin/fast-nix-optimise"
        );

        # Nix-Darwin config options
        # Check corresponding shared imported module
        nix = {
          # Options that aren't supported through nix-darwin
          extraOptions = ''
            # bail early on missing cache hits
            connect-timeout = 10
            stalled-download-timeout = 300
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
      }
    ]
  );
}
