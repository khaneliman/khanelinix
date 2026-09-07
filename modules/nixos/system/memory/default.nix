{ config, lib, ... }:
let
  cfg = config.khanelinix.system.memory;
in
{
  options.khanelinix.system.memory.enable = lib.mkEnableOption "memory management defaults";

  config = lib.mkIf cfg.enable {
    boot.kernel.sysctl = {
      "vm.swappiness" = lib.mkDefault (if config.zramSwap.enable then 100 else 10);
      "vm.vfs_cache_pressure" = lib.mkDefault 50;
      "vm.dirty_ratio" = lib.mkDefault 15;
      "vm.dirty_background_ratio" = lib.mkDefault 5;

      # Heuristic overcommit does not guarantee protection from OOM.
      "vm.overcommit_memory" = lib.mkDefault 0;

      # Zram does not benefit from disk-oriented swap readahead.
      "vm.page-cluster" = lib.mkDefault (if config.zramSwap.enable then 0 else 3);
      "vm.zone_reclaim_mode" = lib.mkDefault 0;
    };
  };
}
