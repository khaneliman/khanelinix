{ options
, config
, pkgs
, lib
, ...
}:
let
  inherit (lib) mkIf types;
  inherit (lib.internal) mkBoolOpt mkOpt;
  cfg = config.khanelinix.hardware.storage;
in
{
  options.khanelinix.hardware.storage = with types; {
    enable =
      mkBoolOpt false
        "Whether or not to enable support for extra storage devices.";
    btrfs = mkBoolOpt false "Whether to enable btrfs extra software;";
    btrfsDedupe = mkBoolOpt false "Whether to enable btrfs deduplication;";
    btrfsScrubMounts = mkOpt (listOf path) [ ] "Btrfs mount paths to scrub;";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs;
      [
        ntfs3g
        fuseiso
        nfs-utils
        btrfs-progs
      ]
      ++ lib.optionals cfg.btrfs [
        btdu
        btrfs-assistant
        btrfs-snap
        compsize
        # dduper
        snapper
      ];

    services.btrfs = mkIf cfg.btrfs {
      autoScrub = {
        enable = true;
        interval = "weekly";

        fileSystems = mkIf (builtins.length cfg.btrfsScrubMounts > 0) cfg.btrfsScrubMounts;
      };
    };
  };
}
