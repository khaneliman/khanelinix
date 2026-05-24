{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.khanelinix.suites.nas;
  inherit (cfg)
    cacheRoot
    cloudRoot
    poolRoot
    userRoot
    ;

  recycleConfig = {
    "fruit:metadata" = "stream";
    "fruit:model" = "MacSamba";
    "fruit:posix_rename" = "yes";
    "fruit:veto_appledouble" = "no";
    "fruit:wipe_intentionally_left_blank_rfork" = "yes";
    "fruit:delete_empty_adfiles" = "yes";
    "recycle:repository" = ".Recycle.Bin";
    "recycle:keeptree" = "yes";
    "recycle:versions" = "yes";
    "recycle:touch" = "yes";
    "recycle:exclude" = "*.tmp *.temp *.o *.obj ~$* *.~??";
    "recycle:exclude_dir" = "/tmp /temp /cache";
  };

  nfsExport = path: "${path} *(rw,async,no_subtree_check,insecure,all_squash,anonuid=99,anongid=100)";
in
{
  options.khanelinix.suites.nas = {
    enable = lib.mkEnableOption "NAS suite";

    userRoot = lib.mkOption {
      type = lib.types.path;
      default = "/mnt/user";
      description = "Unraid-compatible user share root.";
    };

    cacheRoot = lib.mkOption {
      type = lib.types.path;
      default = "/mnt/cache";
      description = "Cache pool mount root.";
    };

    cloudRoot = lib.mkOption {
      type = lib.types.path;
      default = "/mnt/disks";
      description = "Cloud mount root.";
    };

    poolRoot = lib.mkOption {
      type = lib.types.path;
      default = "/mnt/pool";
      description = "Auxiliary pool mount root.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.fuse
    ];

    programs.fuse.userAllowOther = true;

    users = {
      manageLingering = true;
      users.${config.khanelinix.user.name}.linger = true;
    };

    khanelinix.services.samba = {
      enable = true;
      shares = {
        appdata = {
          browseable = true;
          comment = "Application data";
          only-owner-editable = true;
          path = "${userRoot}/appdata";
          public = false;
          read-only = false;
          extra-config = recycleConfig;
        };

        backup = {
          browseable = true;
          comment = "Backups";
          only-owner-editable = true;
          path = "${userRoot}/backup";
          public = false;
          read-only = false;
          extra-config = recycleConfig;
        };

        data = {
          browseable = true;
          comment = "Data";
          path = "${userRoot}/data";
          public = true;
          read-only = false;
          extra-config = recycleConfig;
        };

        isos = {
          browseable = true;
          comment = "ISO images";
          path = "${userRoot}/isos";
          public = true;
          read-only = false;
          extra-config = recycleConfig;
        };

        timemachine = {
          browseable = true;
          comment = "Time Machine backups";
          only-owner-editable = true;
          path = "${userRoot}/timemachine";
          public = false;
          read-only = false;
          extra-config = recycleConfig // {
            "fruit:time machine" = "yes";
          };
        };
      };
    };

    services = {
      nfs.server = {
        enable = true;
        exports = lib.concatStringsSep "\n" (
          map nfsExport [
            "${userRoot}/appdata"
            "${userRoot}/data"
            "${userRoot}/isos"
            "${cloudRoot}/dropbox"
            "${cloudRoot}/googledrive"
            "${cloudRoot}/googlephotos"
            "${cloudRoot}/onedrive"
          ]
        );
      };

      rpcbind.enable = true;
    };

    networking.firewall = {
      allowedTCPPorts = [
        111
        2049
        20048
      ];
      allowedUDPPorts = [
        111
        2049
        20048
      ];
    };

    systemd.tmpfiles.rules = [
      "d ${userRoot} 0775 ${config.khanelinix.user.name} users -"
      "d ${cacheRoot} 0775 ${config.khanelinix.user.name} users -"
      "d ${cloudRoot} 0775 ${config.khanelinix.user.name} users -"
      "d ${poolRoot} 0775 ${config.khanelinix.user.name} users -"
      "d ${poolRoot}/vfs 0775 ${config.khanelinix.user.name} users -"
      "d ${userRoot}/appdata 0775 ${config.khanelinix.user.name} users -"
      "d ${userRoot}/backup 0775 ${config.khanelinix.user.name} users -"
      "d ${userRoot}/data 0775 ${config.khanelinix.user.name} users -"
      "d ${userRoot}/isos 0775 ${config.khanelinix.user.name} users -"
      "d ${userRoot}/timemachine 0775 ${config.khanelinix.user.name} users -"
      "d ${cloudRoot}/dropbox 0775 ${config.khanelinix.user.name} users -"
      "d ${cloudRoot}/googledrive 0775 ${config.khanelinix.user.name} users -"
      "d ${cloudRoot}/googlephotos 0775 ${config.khanelinix.user.name} users -"
      "d ${cloudRoot}/onedrive 0775 ${config.khanelinix.user.name} users -"
    ];
  };
}
