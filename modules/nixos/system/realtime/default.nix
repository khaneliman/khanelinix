{
  config,
  lib,
  khanelinix-lib,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (khanelinix-lib) mkBoolOpt;

  cfg = config.khanelinix.system.realtime;
in
{
  options.khanelinix.system.realtime = {
    enable = mkBoolOpt false "Whether or not to configure realtime.";
  };

  config = mkIf cfg.enable {
    # port of https://gitlab.archlinux.org/archlinux/packaging/packages/realtime-privileges
    # see https://wiki.archlinux.org/title/Realtime_process_management
    # tldr: realtime processes have higher priority than normal processes
    # and that's a good thing
    users = {
      users."${config.khanelinix.user.name}".extraGroups = [ "realtime" ];
      groups.realtime = { };
    };

    services.udev.extraRules = ''
      KERNEL=="cpu_dma_latency", GROUP="realtime"
    '';

    security.pam.loginLimits = [
      {
        domain = "@realtime";
        type = "-";
        item = "rtprio";
        value = 98;
      }
      {
        domain = "@realtime";
        type = "-";
        item = "memlock";
        value = "unlimited";
      }
      {
        domain = "@realtime";
        type = "-";
        item = "nice";
        value = -11;
      }
    ];
  };
}
