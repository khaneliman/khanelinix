{ options
, config
, pkgs
, lib
, ...
}:
let
  inherit (lib) mkIf types genAttrs getExe;
  inherit (lib.internal) mkBoolOpt mkOpt;
  cfg = config.khanelinix.hardware.storage.btrfs;
  inherit (cfg) dedupeFilesystems;

  dedupeFilesystemsAttrSets = genAttrs dedupeFilesystems
    (name: {
      spec = "LABEL=${name}";
      hashTableSizeMB = 1024;
      verbosity = "info";
      workDir = ".beeshome";
      extraOptions = [ "--thread-factor" "0.2" "--loadavg-target" "10" ];
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
    dedupeFilesystems = mkOpt (listOf str) [ ] "Unique btrfs filesystems to dedupe;";
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

    systemd.services.cpulimit-bees = {
      description = "CPU Limit Bees";
      enable = cfg.dedupe;

      after = [ "sysinit.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        ExecStart = "${getExe pkgs.cpulimit} -e bees -l 20";
        Restart = "always";
      };
    };

  };
}
