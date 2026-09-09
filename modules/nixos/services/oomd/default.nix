{
  config,
  lib,

  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.khanelinix.services.oomd;
in
{
  options.khanelinix.services.oomd = {
    enable = lib.mkEnableOption "oomd";
  };

  config = mkIf cfg.enable {
    systemd = {
      # No slice is monitored by default. A unit opts in by setting
      # ManagedOOMMemoryPressure=kill on itself, as the comfyui service does;
      # everything else only sees the hard MemoryMax caps set on the unit.
      oomd = {
        enable = true;
        enableRootSlice = false;
        enableSystemSlice = false;
        enableUserSlices = false;
        settings.OOM = {
          "DefaultMemoryPressureDurationSec" = "20s";
        };
      };

      # Make sure it loads after the swap is setup.
      services.systemd-oomd.after = [ "swap.target" ];
    };
  };
}
