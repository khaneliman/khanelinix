{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.system.realtime;
in
{
  options.${namespace}.system.realtime = {
    enable = mkBoolOpt false "Whether or not to configure xkb.";
  };

  config = mkIf cfg.enable {
    # port of https://gitlab.archlinux.org/archlinux/packaging/packages/realtime-privileges
    # see https://wiki.archlinux.org/title/Realtime_process_management
    # tldr: realtime processes have higher priority than normal processes
    # and that's a good thing
    users = {
      users."${config.${namespace}.user.name}".extraGroups = [ "realtime" ];
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
