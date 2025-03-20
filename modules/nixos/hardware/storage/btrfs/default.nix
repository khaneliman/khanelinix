{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib)
    mkIf
    types
    genAttrs
    getExe
    ;
  inherit (lib.${namespace}) mkOpt;
  inherit (cfg) dedupeFilesystems;

  cfg = config.${namespace}.hardware.storage.btrfs;

  dedupeFilesystemsAttrSets = genAttrs dedupeFilesystems (name: {
    spec = "LABEL=${name}";
    hashTableSizeMB = 1024;
    verbosity = "info";
    workDir = ".beeshome";
    extraOptions = [
      "--thread-factor"
      "0.1"
      "--loadavg-target"
      "5"
    ];
  });
in
{
  options.${namespace}.hardware.storage.btrfs = with types; {
    enable = lib.mkEnableOption "support for btrfs devices";
    autoScrub = lib.mkEnableOption "btrfs autoScrub;";
    dedupe = lib.mkEnableOption "btrfs deduplication;";
    dedupeFilesystems = mkOpt (listOf str) [ ] "Unique btrfs filesystems to dedupe;";
    scrubMounts = mkOpt (listOf path) [ ] "Btrfs mount paths to scrub;";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      btdu
      btrfs-assistant
      btrfs-snap
      compsize
      snapper
    ];

    services = {
      btrfs = {
        autoScrub = mkIf cfg.autoScrub {
          enable = true;
          fileSystems = mkIf (builtins.length cfg.scrubMounts > 0) cfg.scrubMounts;
          interval = "weekly";
        };
      };

      beesd = mkIf cfg.dedupe {
        filesystems = mkIf (builtins.length dedupeFilesystems > 0) dedupeFilesystemsAttrSets;
      };
    };

    systemd.services.cpulimit-bees = {
      enable = cfg.dedupe;
      after = [ "sysinit.target" ];
      description = "CPU Limit Bees";
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        ExecStart = "${getExe pkgs.cpulimit} -e bees -l 20";
        Restart = "always";
      };
    };
  };
}
