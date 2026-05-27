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
      description = "Unraid-compatible user share root for first-deploy migration.";
    };

    cacheRoot = lib.mkOption {
      type = lib.types.path;
      default = "/mnt/cache";
      description = "Unraid-compatible cache pool root for first-deploy migration.";
    };

    cloudRoot = lib.mkOption {
      type = lib.types.path;
      default = "/mnt/disks";
      description = "Unraid-compatible external/cloud mount root for first-deploy migration.";
    };

    poolRoot = lib.mkOption {
      type = lib.types.path;
      default = "/mnt/pool";
      description = "Unraid-compatible auxiliary pool root for first-deploy migration.";
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

        data = {
          browseable = true;
          comment = "Data";
          path = "${userRoot}/data";
          public = true;
          read-only = false;
          extra-config = recycleConfig;
        };

        familyphotos = {
          browseable = true;
          comment = "Family photos";
          path = "${userRoot}/familyphotos";
          public = true;
          read-only = false;
          extra-config = recycleConfig;
        };

        gamingvideos = {
          browseable = true;
          comment = "Gaming videos";
          path = "${userRoot}/gamingvideos";
          public = true;
          read-only = false;
          extra-config = recycleConfig;
        };

        homevideos = {
          browseable = true;
          comment = "Home videos";
          path = "${userRoot}/homevideos";
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

        pictures = {
          browseable = true;
          comment = "Place to drop pictures for import to PhotoPrism.";
          path = "${userRoot}/pictures";
          public = true;
          read-only = false;
          extra-config = recycleConfig;
        };

        tv = {
          browseable = true;
          comment = "TV";
          path = "${userRoot}/tv";
          public = true;
          read-only = false;
          extra-config = recycleConfig;
        };

        tvrecordings = {
          browseable = true;
          comment = "TV recordings";
          path = "${userRoot}/tvrecordings";
          public = true;
          read-only = false;
          extra-config = recycleConfig;
        };

        dropbox = {
          browseable = true;
          comment = "Dropbox cloud mount";
          path = "${cloudRoot}/dropbox";
          public = true;
          read-only = false;
          extra-config = recycleConfig;
        };

        googledrive = {
          browseable = true;
          comment = "Google Drive cloud mount";
          path = "${cloudRoot}/googledrive";
          public = true;
          read-only = false;
          extra-config = recycleConfig;
        };

        googlephotos = {
          browseable = true;
          comment = "Google Photos cloud mount";
          path = "${cloudRoot}/googlephotos";
          public = true;
          read-only = false;
          extra-config = recycleConfig;
        };

        onedrive = {
          browseable = true;
          comment = "OneDrive cloud mount";
          path = "${cloudRoot}/onedrive";
          public = true;
          read-only = false;
          extra-config = recycleConfig;
        };
      };
    };

    services = {
      nfs.server = {
        enable = true;
        exports = lib.concatStringsSep "\n" (
          map nfsExport [
            "${userRoot}/appdata"
            "${userRoot}/backup"
            "${userRoot}/data"
            "${userRoot}/familyphotos"
            "${userRoot}/gamingvideos"
            "${userRoot}/homevideos"
            "${userRoot}/isos"
            "${userRoot}/pictures"
            "${userRoot}/tv"
            "${userRoot}/tvrecordings"
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

    # TODO: replace these Unraid-compatible /mnt roots with more idiomatic
    # NixOS mountpoints after the initial khanelilab migration is stable.
    systemd.tmpfiles.rules = [
      "d ${userRoot} 0775 ${config.khanelinix.user.name} users -"
      "d ${cacheRoot} 0775 ${config.khanelinix.user.name} users -"
      "d ${cloudRoot} 0775 ${config.khanelinix.user.name} users -"
      "d ${poolRoot} 0775 ${config.khanelinix.user.name} users -"
      "d ${poolRoot}/vfs 0775 ${config.khanelinix.user.name} users -"
      "d ${userRoot}/Plex 0775 ${config.khanelinix.user.name} users -"
      "d ${userRoot}/appdata 0775 ${config.khanelinix.user.name} users -"
      "d ${userRoot}/backup 0775 ${config.khanelinix.user.name} users -"
      "d ${userRoot}/compose 0775 ${config.khanelinix.user.name} users -"
      "d ${userRoot}/data 0775 ${config.khanelinix.user.name} users -"
      "d ${userRoot}/domains 0775 ${config.khanelinix.user.name} users -"
      "d ${userRoot}/familyphotos 0775 ${config.khanelinix.user.name} users -"
      "d ${userRoot}/gamingvideos 0775 ${config.khanelinix.user.name} users -"
      "d ${userRoot}/homevideos 0775 ${config.khanelinix.user.name} users -"
      "d ${userRoot}/isos 0775 ${config.khanelinix.user.name} users -"
      "d ${userRoot}/pictures 0775 ${config.khanelinix.user.name} users -"
      "d ${userRoot}/syslog 0775 ${config.khanelinix.user.name} users -"
      "d ${userRoot}/system 0775 ${config.khanelinix.user.name} users -"
      "d ${userRoot}/temp 0775 ${config.khanelinix.user.name} users -"
      "d ${userRoot}/timemachine 0775 ${config.khanelinix.user.name} users -"
      "d ${userRoot}/tv 0775 ${config.khanelinix.user.name} users -"
      "d ${userRoot}/tvrecordings 0775 ${config.khanelinix.user.name} users -"
      "d ${userRoot}/vfs 0775 ${config.khanelinix.user.name} users -"
      "d ${userRoot}/vfsMeta 0775 ${config.khanelinix.user.name} users -"
      "d ${cloudRoot}/dropbox 0775 ${config.khanelinix.user.name} users -"
      "d ${cloudRoot}/googledrive 0775 ${config.khanelinix.user.name} users -"
      "d ${cloudRoot}/googlephotos 0775 ${config.khanelinix.user.name} users -"
      "d ${cloudRoot}/onedrive 0775 ${config.khanelinix.user.name} users -"
    ];
  };
}
