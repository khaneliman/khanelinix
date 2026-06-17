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
  mkNixJobWrapper =
    name: command:
    pkgs.writeShellScript name ''
      set +e
      log() {
        /bin/printf '%s %s\n' "[$(/bin/date -u '+%FT%TZ')][${name}]" "$1"
      }

      log "starting"
      ${triggerSketchybarNixUpdate}
      ${command}
      status=$?
      log "finished status=$status"
      ${triggerSketchybarNixUpdate}
      exit $status
    '';
  gcWrapper = mkNixJobWrapper "nix-gc-with-sketchybar-update" "/usr/bin/caffeinate -i -s ${fastNixGc}/bin/fast-nix-gc ${config.nix.gc.options}";
  optimiseWrapper = mkNixJobWrapper "nix-optimise-with-sketchybar-update" "/usr/bin/caffeinate -i -s ${fastNixGc}/bin/fast-nix-optimise";
  nixJobLogPaths = {
    gc = {
      stdout = "/var/log/nix-gc.out.log";
      stderr = "/var/log/nix-gc.err.log";
    };
    optimise = {
      stdout = "/var/log/nix-optimise.out.log";
      stderr = "/var/log/nix-optimise.err.log";
    };
  };
  nixLogRotationEntries = {
    gc = [
      {
        logfilename = nixJobLogPaths.gc.stderr;
        mode = "644";
        owner = "root";
        group = "wheel";
        count = 7;
        size = "2048";
        flags = [
          "Z"
          "C"
        ];
      }
      {
        logfilename = nixJobLogPaths.gc.stdout;
        mode = "644";
        owner = "root";
        group = "wheel";
        count = 7;
        size = "2048";
        flags = [
          "Z"
          "C"
        ];
      }
    ];
    optimise = [
      {
        logfilename = nixJobLogPaths.optimise.stderr;
        mode = "644";
        owner = "root";
        group = "wheel";
        count = 7;
        size = "2048";
        flags = [
          "Z"
          "C"
        ];
      }
      {
        logfilename = nixJobLogPaths.optimise.stdout;
        mode = "644";
        owner = "root";
        group = "wheel";
        count = 7;
        size = "2048";
        flags = [
          "Z"
          "C"
        ];
      }
    ];
  };
in
{
  imports = [ (lib.getFile "modules/common/nix/default.nix") ];

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      (lib.mkIf config.nix.gc.automatic {
        # Only override the GC daemon command when the daemon is actually enabled.
        launchd.daemons.nix-gc = {
          command = lib.mkForce "${gcWrapper}";
          serviceConfig = {
            StandardOutPath = nixJobLogPaths.gc.stdout;
            StandardErrorPath = nixJobLogPaths.gc.stderr;

            # Idle CPU + throttled disk I/O so maintenance yields to foreground
            # work instead of stalling the shared APFS container and tripping
            # the WindowServer watchdog.
            ProcessType = "Background";
            LowPriorityIO = true;
          };
        };
      })
      {
        system.newsyslog.files.nix-gc = nixLogRotationEntries.gc;
        system.newsyslog.files.nix-optimise = nixLogRotationEntries.optimise;

        # Wrap optimise in caffeinate to prevent sleep while running.
        launchd.daemons.nix-optimise = {
          command = lib.mkForce "${optimiseWrapper}";
          serviceConfig = {
            StandardOutPath = nixJobLogPaths.optimise.stdout;
            StandardErrorPath = nixJobLogPaths.optimise.stderr;

            # Idle CPU + throttled disk I/O (see nix-gc); optimise scans ~2M
            # link inodes and was the worst APFS-contention offender.
            ProcessType = "Background";
            LowPriorityIO = true;
          };
        };

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
            # Weekly (Sunday) rather than daily. optimise.interval below derives
            # from this, so both heavy maintenance jobs run once a week.
            interval = [
              {
                Weekday = 0;
                Hour = 3;
                Minute = 15;
              }
            ];
            options = "--delete-older-than 7d";
          };

          # Optimize nix store after cleaning (inherits the weekly schedule, +1h)
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
