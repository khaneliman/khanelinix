{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.khanelinix.services.ludusavi;
in
{
  options.khanelinix.services.ludusavi = {
    enable = lib.mkEnableOption "versioned game save backups";

    backupDirectory = lib.mkOption {
      type = lib.types.str;
      default = "${config.xdg.stateHome}/backups/ludusavi";
      description = "Directory containing game save backup history.";
    };

    networkMount = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "NFS mount that must be available before backing up, if any.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.networkMount == null || lib.hasPrefix "${cfg.networkMount}/" cfg.backupDirectory;
        message = "Ludusavi's backup directory must be inside its required NFS mount.";
      }
    ];

    services.ludusavi = {
      enable = true;
      frequency = "hourly";
      settings = {
        roots = [
          {
            path = "${config.xdg.dataHome}/Steam";
            store = "steam";
          }
          {
            path = "${config.xdg.configHome}/heroic";
            store = "heroic";
          }
          {
            path = "${config.xdg.configHome}/lutris";
            store = "lutris";
            database = "${config.xdg.dataHome}/lutris/pga.db";
          }
        ];

        backup = {
          path = cfg.backupDirectory;
          retention = {
            full = 3;
            differential = 6;
          };
          format = {
            chosen = "zip";
            zip.compression = "zstd";
          };
        };
        restore.path = cfg.backupDirectory;

        # Worlds, mods, and instance settings are needed to recover a modpack.
        customGames = lib.optional config.khanelinix.programs.graphical.apps.prismlauncher.enable {
          name = "Prism Launcher instances";
          files = [ "${config.xdg.dataHome}/PrismLauncher/instances" ];
        };
      };
    };

    systemd.user = {
      services.ludusavi.Service = {
        Nice = 19;
        IOSchedulingClass = "idle";
        UMask = "0077";
        TimeoutStartSec = "30min";
        ExecCondition = lib.mkIf (cfg.networkMount != null) (
          lib.getExe (
            pkgs.writeShellScriptBin "ludusavi-check-mount" ''
              set -eu
              # Trigger automount before checking; never back up to its local stub.
              if ! ${lib.getExe' pkgs.coreutils "timeout"} 15 \
                ${lib.getExe' pkgs.coreutils "stat"} -- ${lib.escapeShellArg "${cfg.networkMount}/."} >/dev/null \
                || ! ${lib.getExe' pkgs.util-linux "findmnt"} --noheadings --types nfs,nfs4 \
                  --mountpoint ${lib.escapeShellArg cfg.networkMount} >/dev/null; then
                echo "Skipping game save backup: NFS mount is unavailable." >&2
                exit 1
              fi
            ''
          )
        );
      };
      timers.ludusavi.Timer.Persistent = true;
    };
  };
}
