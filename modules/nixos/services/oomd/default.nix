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
      # Monitor explicitly opted-in workloads, not entire sessions.
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
