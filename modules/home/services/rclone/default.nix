{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.khanelinix.services.rclone;

  mountType =
    with lib.types;
    submodule (
      { name, ... }:
      {
        options = {
          remote = lib.mkOption {
            type = str;
            default = name;
            description = "The rclone remote name to mount.";
          };

          remotePath = lib.mkOption {
            type = str;
            default = "";
            description = "The path within the rclone remote.";
          };

          mountPoint = lib.mkOption {
            type = path;
            description = "The local mount point.";
          };

          options = lib.mkOption {
            type = attrsOf (oneOf [
              bool
              int
              float
              str
            ]);
            default = { };
            description = "Options passed to rclone mount.";
          };
        };
      }
    );

  mkMountService =
    mount:
    let
      remote = "${mount.remote}:${mount.remotePath}";
      options = {
        allow-other = true;
        cache-dir = cfg.cacheDir;
        dir-cache-time = "1000h";
        uid = "99";
        gid = "100";
        vfs-cache-mode = "full";
        vfs-read-ahead = "256M";
      }
      // mount.options;
    in
    {
      Unit = {
        Description = "Rclone FUSE daemon for ${remote}";
        ConditionPathExists = cfg.configFile;
        After = [ "network-online.target" ];
        Wants = [ "network-online.target" ];
      };

      Service = {
        Environment = "PATH=/run/wrappers/bin:/run/current-system/sw/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin";
        ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p ${lib.escapeShellArg (toString mount.mountPoint)} ${lib.escapeShellArg cfg.cacheDir}";
        ExecStart = lib.concatStringsSep " " [
          "${lib.getExe cfg.package} mount"
          "--config ${lib.escapeShellArg cfg.configFile}"
          (lib.cli.toCommandLineShellGNU { } options)
          (lib.escapeShellArg remote)
          (lib.escapeShellArg (toString mount.mountPoint))
        ];
        ExecStop = "${pkgs.fuse}/bin/fusermount -u ${lib.escapeShellArg (toString mount.mountPoint)}";
        Restart = "on-failure";
        RestartSec = "10s";
        SuccessExitStatus = "143";
        Type = "notify";
      };

      Install.WantedBy = [ "default.target" ];
    };
in
{
  options.khanelinix.services.rclone = {
    enable = lib.mkEnableOption "rclone mounts";

    package = lib.mkPackageOption pkgs "rclone" { };

    configFile = lib.mkOption {
      type = lib.types.path;
      default = "/run/secrets/rclone/config";
      description = "The rclone config file to use for mounts.";
    };

    cacheDir = lib.mkOption {
      type = lib.types.path;
      default = "/mnt/pool/vfs";
      description = "The rclone VFS cache directory.";
    };

    mounts = lib.mkOption {
      type = lib.types.attrsOf mountType;
      default = { };
      description = "Rclone FUSE mounts to create as systemd user services.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      cfg.package
      pkgs.fuse
    ];

    systemd.user.services = lib.mapAttrs' (
      name: mount: lib.nameValuePair "rclone-${name}" (mkMountService mount)
    ) cfg.mounts;
  };
}
