{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) mkIf;
  inherit (flake.inputs.self.lib.khanelinix) mkBoolOpt;

  cfg = config.khanelinix.system.time;
in
{
  options.khanelinix.system.time = {
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
