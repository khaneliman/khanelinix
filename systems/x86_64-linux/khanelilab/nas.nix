{
  config,
  lib,
  pkgs,
  ...
}:
let
  user = config.khanelinix.user.name;
  localShares = [
    "appdata"
    "data"
    "isos"
  ];
  cloudShares = {
    dropbox = "dropbox";
    google = "googledrive";
    onedrive = "onedrive";
  };
  share = path: {
    inherit path;
    public = false;
    read-only = false;
    extra-config = {
      "valid users" = user;
      "write list" = user;
      "create mask" = "0777";
      "directory mask" = "0777";
    };
  };
  export =
    path: fsid: mountpoint:
    "${path} 100.64.0.0/10(rw,async,no_subtree_check,insecure,all_squash,anonuid=99,anongid=100,fsid=${toString fsid},mp=${mountpoint})";
in
{
  khanelinix.services.samba.shares = lib.mkForce (
    lib.genAttrs localShares (
      name:
      lib.recursiveUpdate (share "/mnt/user/${name}") {
        extra-config = {
          "vfs objects" = "catia fruit streams_xattr recycle";
          "recycle:repository" = ".Recycle.Bin";
          "recycle:keeptree" = "yes";
          "recycle:versions" = "yes";
          "fruit:metadata" = "stream";
        };
      }
    )
    // lib.mapAttrs (
      _: remote:
      lib.recursiveUpdate (share "/mnt/disks/${remote}") {
        extra-config = {
          "root preexec" = "${pkgs.util-linux}/bin/mountpoint -q /mnt/disks/${remote}";
          "root preexec close" = "yes";
        };
      }
    ) cloudShares
  );

  services.samba.settings.global = {
    "server string" = "Media server";
    "map to guest" = "Bad User";
    "passdb backend" = "smbpasswd:/var/lib/samba/private/smbpasswd";
  };
  sops.secrets."samba/passwd" = {
    sopsFile = lib.getFile "secrets/khanelilab/services.yaml";
    key = "samba-passwd";
  };

  services.nfs.server.exports = lib.mkForce (
    lib.concatStringsSep "\n" [
      (export "/mnt/user/appdata" 100 "/mnt/user")
      (export "/mnt/user/data" 102 "/mnt/user")
      (export "/mnt/user/isos" 103 "/mnt/user")
      (export "/mnt/disks/dropbox" 200 "/mnt/disks/dropbox")
      (export "/mnt/disks/googledrive" 201 "/mnt/disks/googledrive")
      (export "/mnt/disks/googlephotos" 202 "/mnt/disks/googlephotos")
      (export "/mnt/disks/onedrive" 203 "/mnt/disks/onedrive")
    ]
  );
  systemd.services = {
    samba-identity = {
      before = [
        "samba-smbd.service"
        "samba-nmbd.service"
      ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        UMask = "0077";
      };
      path = [
        pkgs.coreutils
        config.services.samba.package
      ];
      script = ''
        install -d -m 0700 /var/lib/samba/private
        if [ ! -e /var/lib/samba/private/smbpasswd ]; then
          install -m 0600 ${config.sops.secrets."samba/passwd".path} /var/lib/samba/private/smbpasswd
        fi
        net -s /etc/samba/smb.conf setlocalsid S-1-5-21-3080858225-3095825074-865487820
      '';
    };
    samba-smbd = {
      requires = [ "samba-identity.service" ];
      after = [ "samba-identity.service" ];
      unitConfig.RequiresMountsFor = [ "/mnt/user" ];
    };
    samba-nmbd = {
      requires = [ "samba-identity.service" ];
      after = [ "samba-identity.service" ];
    };
    nfs-mountd = {
      after = [ "systemd-tmpfiles-setup.service" ];
      unitConfig.RequiresMountsFor = [ "/mnt/user" ];
    };
    nfs-server.unitConfig.RequiresMountsFor = [ "/mnt/user" ];
  };
}
