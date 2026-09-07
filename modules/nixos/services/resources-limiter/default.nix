{
  config,
  lib,

  ...
}:
let
  inherit (lib) mkIf mkEnableOption;

  cfg = config.khanelinix.services.resources-limiter;
in
{
  options.khanelinix.services.resources-limiter = {
    enable = mkEnableOption "resources limiter slice";
    memoryHigh = lib.mkOption {
      type = lib.types.str;
      default = "25%";
      description = "Memory usage at which build workloads are throttled.";
    };
    memoryMax = lib.mkOption {
      type = lib.types.str;
      default = "infinity";
      description = "Hard memory limit shared by build workloads.";
    };
    memorySwapMax = lib.mkOption {
      type = lib.types.str;
      default = "infinity";
      description = "Maximum swap usage shared by build workloads.";
    };
  };

  config = mkIf cfg.enable {
    systemd = {
      # DOCS https://www.freedesktop.org/software/systemd/man/latest/systemd.resource-control.html
      # Weights compete at the root alongside system.slice and user.slice.
      slices.resources.sliceConfig = {
        CPUWeight = 20;
        IOWeight = 20;
      };
      slices.resources-limiter.sliceConfig = {
        MemoryAccounting = true;
        MemoryHigh = cfg.memoryHigh;
        MemoryMax = cfg.memoryMax;
        MemorySwapMax = cfg.memorySwapMax;
      };

      services = {
        nixos-upgrade.serviceConfig.Slice = "resources-limiter.slice";
        nix-daemon.serviceConfig.Slice = "resources-limiter.slice";
      };
    };
  };
}
