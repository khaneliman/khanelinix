{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.${namespace}.nix.linux-builder;
in
{
  options.${namespace}.nix.linux-builder = {
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
  };
}
