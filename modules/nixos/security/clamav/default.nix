{
  config,
  lib,
  pkgs,

  ...
}:
let
  cfg = config.khanelinix.security.clamav;
  scanDirectories = [
    "/home"
    "/var/lib"
    "/tmp"
    "/var/log"
    "/var/tmp"
  ];
in
{
  options.khanelinix.security.clamav = {
    enable = lib.mkEnableOption "default clamav configuration";
  };

  config = lib.mkIf cfg.enable {
    services.clamav = {
      daemon.enable = false;
      scanner.enable = false;

      fangfrisch = {
        enable = true;
      };

      updater = {
        enable = true;
      };
    };

    systemd.services.clamav-scan = {
      description = "Scheduled ClamAV scan";
      serviceConfig = {
        Type = "oneshot";
        Nice = 19;
        IOSchedulingClass = "best-effort";
        IOSchedulingPriority = 7;
        SuccessExitStatus = [ 1 ];
      };
      script = ''
        ${pkgs.clamav}/bin/clamscan \
          --recursive \
          --infected \
          ${lib.concatStringsSep " " scanDirectories}
      '';
    };

    systemd.timers.clamav-scan = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "weekly";
        Persistent = true;
        RandomizedDelaySec = "1h";
        Unit = "clamav-scan.service";
      };
    };
  };
}
