{
  config,
  lib,

  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.khanelinix.nix.linux-builder;
in
{
  options.khanelinix.nix.linux-builder = {
    enable = lib.mkEnableOption "linux-builder";
    cores = lib.mkOption {
      type = lib.types.int;
      default = 8;
      description = "Number of cores to use for the builder.";
    };
    maxJobs = lib.mkOption {
      type = lib.types.int;
      default = 4;
      description = "Number of jobs to run in parallel.";
    };
    memory = lib.mkOption {
      type = lib.types.int;
      default = 8192;
      description = "Memory to use for the builder (in MiB).";
    };
    speedFactor = lib.mkOption {
      type = lib.types.int;
      default = 15;
      description = "Speed factor for the builder.";
    };
  };

  config = mkIf cfg.enable {
    # NOTE: Always requires building when providing configuration.
    # Depends on having linux builders available to... build the linux builder.
    # If none are available, only enable without customization.
    nix.linux-builder = {
      inherit (cfg) maxJobs speedFactor;

      enable = true;
      ephemeral = true;

      supportedFeatures = [
        "big-parallel"
        "nixos-test"
      ];

      config = {
        virtualisation = {
          inherit (cfg) cores;
          darwin-builder.memorySize = cfg.memory;
        };
      };
    };

    launchd.daemons.linux-builder = {
      serviceConfig = {
        StandardOutPath = "/var/log/linux-builder.log";
        StandardErrorPath = "/var/log/linux-builder.log";
      };
    };
  };
}
