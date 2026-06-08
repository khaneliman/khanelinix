{
  config,
  lib,
  pkgs,

  ...
}:
let
  cfg = config.khanelinix.security.clamav;
  excludedDirectories = [
    "(^|/)\\.cache($|/)"
    "(^|/)\\.git($|/)"
    "(^|/)\\.hg($|/)"
    "(^|/)\\.svn($|/)"
    "(^|/)\\.Trash-[0-9]+($|/)"
  ];
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
        IOSchedulingClass = "idle";
        RuntimeMaxSec = "6h";
        SuccessExitStatus = [ 1 ];
      };
      script = ''
        ${pkgs.clamav}/bin/clamscan \
          --recursive \
          --infected \
          --cross-fs=no \
          ${
            lib.concatMapStringsSep " \\\n          " (
              pattern: "--exclude-dir='${pattern}'"
            ) excludedDirectories
          } \
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
