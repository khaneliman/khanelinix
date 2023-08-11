{ config
, lib
, ...
}:
let
  cfg = config.khanelinix.system.zfs;

  inherit (lib) mkEnableOption mkIf mkDefault;
  inherit (lib.internal) mkOpt enabled;
  inherit (lib.types) listOf str;
in
{
  options.khanelinix.system.zfs = {
    enable = mkEnableOption "ZFS support";

    pools = mkOpt (listOf str) [ "rpool" ] "The ZFS pools to manage.";

    auto-snapshot = {
      enable = mkEnableOption "ZFS auto snapshotting";
    };
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
