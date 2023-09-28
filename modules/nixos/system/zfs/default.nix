{ config
, lib
, ...
}:
let
  inherit (lib) mkEnableOption mkIf mkDefault;
  inherit (lib.internal) mkOpt;
  inherit (lib.types) listOf str;

  cfg = config.khanelinix.system.zfs;
in
{
  options.khanelinix.system.zfs = {
    enable = mkEnableOption "ZFS support";
    auto-snapshot = {
      enable = mkEnableOption "ZFS auto snapshotting";
    };
    pools = mkOpt (listOf str) [ "rpool" ] "The ZFS pools to manage.";
  };

  config = mkIf cfg.enable {
    boot.kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;

    services.zfs = {
      autoScrub = {
        enable = true;
        inherit (cfg) pools;
      };

      autoSnapshot = mkIf cfg.auto-snapshot.enable {
        enable = true;
        daily = mkDefault 3;
        flags = "-k -p --utc";
        frequent = mkDefault 0;
        hourly = mkDefault 0;
        monthly = mkDefault 2;
        weekly = mkDefault 3;
      };
    };
  };
}
