{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.${namespace}.system.time;
in
{
  options.${namespace}.system.time = {
    enable = lib.mkEnableOption "time related settings";
  };

  config = mkIf cfg.enable {
    networking.timeServers = [
      # NTP servers from the NTP Pool Project
      "us.pool.ntp.org"
      # NTP servers from Google
      "time1.google.com"
      "time2.google.com"
      "time3.google.com"
      "time4.google.com"
      # NTP servers from NixOS
      "0.nixos.pool.ntp.org"
      "1.nixos.pool.ntp.org"
      "2.nixos.pool.ntp.org"
      "3.nixos.pool.ntp.org"
    ];

    services.chrony = {
      enable = true;
      # Not supported by nixos pool
      # enableNTS = true;
    };

    # Make sure we can resolve the timeservers
    systemd.services.chronyd = {
      after =
        lib.optional config.services.resolved.enable "systemd-resolved.service"
        ++ lib.optional config.services.dnsmasq.enable "dnsmasq.service";
    };

    time.timeZone = "America/Chicago";
  };
}
