{
  config,
  lib,
  pkgs,
  ...
}:
let
  user = config.khanelinix.user.name;
  uid = toString config.users.users.${user}.uid;
in
{
  sops.secrets."rclone/config" = {
    sopsFile = lib.getFile "secrets/khanelilab/services.yaml";
    key = "rclone-config";
    owner = user;
  };

  systemd.services.rclone-state-directory = {
    requires = [ "mnt-pool.mount" ];
    after = [ "mnt-pool.mount" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.coreutils}/bin/install -d -m 0700 -o ${user} -g users /mnt/pool/appdata/rclone";
    };
  };
  systemd.services."user@${uid}" = {
    overrideStrategy = "asDropin";
    requires = [ "rclone-state-directory.service" ];
    after = [
      "rclone-state-directory.service"
      "systemd-tmpfiles-setup.service"
    ];
  };
}
