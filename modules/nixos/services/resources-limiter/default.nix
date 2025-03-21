{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkIf mkEnableOption;

  cfg = config.${namespace}.services.resources-limiter;
in
{
  options.${namespace}.services.resources-limiter = {
    enable = mkEnableOption "resources limiter slice";
  };

  config = mkIf cfg.enable {
    systemd = {
      # DOCS https://www.freedesktop.org/software/systemd/man/latest/systemd.resource-control.html
      slices.resources-limiter.sliceConfig = {
        CPUAccounting = true;
        CPUQuota = "50%";
        MemoryAccounting = true;
        MemoryHigh = "50%";
        MemoryMax = "75%";
        MemorySwapMax = "50%";
        MemoryZSwapMax = "50%";
      };

      services.nix-daemon.serviceConfig.Slice = "resources-limiter.slice";
    };
  };
}
