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
  gcInterval = [
    {
      Weekday = 0;
      Hour = 3;
      Minute = 15;
    }
  ];
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
      export PATH=${lib.makeBinPath [ config.nix.package ]}:/usr/bin:/bin

      log() {
        printf '%s %s\n' "[$(/bin/date -u '+%FT%TZ')][${name}]" "$1"
      }

      log "starting"
      ${triggerSketchybarNixUpdate}
      ${lib.escapeShellArgs command}
      status=$?
      log "finished status=$status"
      ${triggerSketchybarNixUpdate}
      exit $status
    '';
  gcWrapper = mkNixJobWrapper "nix-gc-with-sketchybar-update" (
    [
      "/usr/bin/caffeinate"
      "-i"
      "-s"
    ]
    ++ config.services.fast-nix-gc.argv
  );
  optimiseWrapper = mkNixJobWrapper "nix-optimise-with-sketchybar-update" (
    [
      "/usr/bin/caffeinate"
      "-i"
      "-s"
    ]
    ++ config.services.fast-nix-optimise.argv
  );
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
  imports = [
    inputs.fast-nix-gc.darwinModules.default
    (lib.getFile "modules/common/nix/default.nix")
  ];

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      (lib.mkIf config.services.fast-nix-gc.automatic {
        launchd.daemons.fast-nix-gc = {
          serviceConfig = {
            ProgramArguments = lib.mkForce [ "${gcWrapper}" ];
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

        launchd.daemons.fast-nix-optimise = {
          serviceConfig = {
            ProgramArguments = lib.mkForce [ "${optimiseWrapper}" ];
            StandardOutPath = nixJobLogPaths.optimise.stdout;
            StandardErrorPath = nixJobLogPaths.optimise.stderr;

            # Idle CPU + throttled disk I/O (see nix-gc); optimise scans ~2M
            # link inodes and was the worst APFS-contention offender.
            ProcessType = "Background";
            LowPriorityIO = true;
          };
        };

        nix = {
          gc = {
            automatic = lib.mkForce false;
            interval = gcInterval;
            options = "--delete-older-than 7d";
          };

          optimise = {
            automatic = lib.mkForce false;
            interval = lib.map (entry: entry // { Hour = entry.Hour + 1; }) gcInterval;
          };

          # Run builds with low priority to keep the system responsive.
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
            min-free = lib.mkForce (20 * 1024 * 1024 * 1024);
            max-free = lib.mkForce (50 * 1024 * 1024 * 1024);
            # FIXME: upstream bug needs to be resolved before fully enabling
            # https://github.com/NixOS/nix/issues/12698
            # TODO: sandbox causes "Bus error: 10" on Darwin 25.2.0, disabling for now.
            sandbox = lib.mkForce false;
          };
        };

        services = {
          fast-nix-gc = {
            enable = true;
            automatic = true;
            package = fastNixGc;
            startCalendarInterval = gcInterval;
            deleteOlderThan = "30d";
            keepRecent = "7d";
          };

          fast-nix-optimise = {
            enable = true;
            automatic = true;
            package = fastNixGc;
            startCalendarInterval = lib.map (entry: entry // { Hour = entry.Hour + 1; }) gcInterval;
          };
        };
      }
    ]
  );
}
