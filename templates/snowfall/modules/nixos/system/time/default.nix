{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.system.time;
in
{
  options.${namespace}.system.time = {
    enable = mkBoolOpt false "Whether or not to configure time related settings.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.openntpd ];

    networking.timeServers = [
      "0.nixos.pool.ntp.org"
      "1.nixos.pool.ntp.org"
      "2.nixos.pool.ntp.org"
      "3.nixos.pool.ntp.org"
    ];

    services.openntpd = {
      enable = true;
      extraConfig = ''
        listen on 127.0.0.1
        listen on ::1
      '';
    };

    time.timeZone = "America/Chicago";
  };
}
