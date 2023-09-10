{ options
, config
, pkgs
, lib
, ...
}:
let
  inherit (lib) mkIf types genAttrs;
  inherit (lib.internal) mkBoolOpt mkOpt;
  cfg = config.khanelinix.hardware.storage.btrfs;
  dedupeFilesystems = cfg.dedupeFilesystems;

  dedupeFilesystemsAttrSets = genAttrs dedupeFilesystems
    (name: {
      spec = "LABEL=${name}";
      hashTableSizeMB = 1024;
      verbosity = "info";
      workDir = ".beeshome";
      extraOptions = [ ];
    });
in
{
  options.khanelinix.hardware.storage.btrfs = with types; {
    enable =
      mkBoolOpt false
        "Whether or not to enable support for btrfs devices.";
    autoScrub = mkBoolOpt false "Whether to enable btrfs autoScrub;";
    dedupe = mkBoolOpt false "Whether to enable btrfs deduplication;";
    scrubMounts = mkOpt (listOf path) [ ] "Btrfs mount paths to scrub;";
    dedupeFilesystems = mkOpt (listOf string) [ ] "Unique btrfs filesystems to dedupe;";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs;
      [
        btdu
        btrfs-assistant
        btrfs-snap
        compsize
        # dduper
        snapper
      ];

    services = {
      btrfs = {
        autoScrub = mkIf cfg.autoScrub {
          enable = true;
          interval = "weekly";

          fileSystems = mkIf (builtins.length cfg.scrubMounts > 0) cfg.scrubMounts;
        };
      };

      beesd = mkIf cfg.dedupe {
        filesystems = mkIf (builtins.length dedupeFilesystems > 0) dedupeFilesystemsAttrSets;
      };
    };
  };
}
