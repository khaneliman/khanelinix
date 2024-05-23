{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkIf mkEnableOption;

  cfg = config.${namespace}.security.auditd;
in
{
  options.${namespace}.security.auditd = {
    enable = mkEnableOption "default auditd configuration";
  };

  config = mkIf cfg.enable {
    security = {
      auditd.enable = true;

      audit = {
        enable = true;
        backlogLimit = 8192;
        failureMode = "printk";
        rules = [ "-a exit,always -F arch=b64 -S execve" ];
      };
    };

    systemd = {
      # a systemd timer to clean /var/log/audit.log daily
      # this can probably be weekly, but daily means we get to clean it every 2-3 days instead of once a week
      timers."clean-audit-log" = {
        description = "Periodically clean audit log";
        timerConfig = {
          OnCalendar = "daily";
          Persistent = true;
        };
        wantedBy = [ "timers.target" ];
      };

      # clean audit log if it's more than 524,288,000 bytes, which is roughly 500 megabytes
      # it can grow MASSIVE in size if left unchecked
      services."clean-audit-log" = {
        script = # bash
          ''
            set -eu
            if [[ $(stat -c "%s" /var/log/audit/audit.log) -gt 524288000 ]]; then
              echo "Clearing Audit Log";
              rm -rvf /var/log/audit/audit.log;
              echo "Done!"
            fi
          '';

        serviceConfig = {
          Type = "oneshot";
          User = "root";
        };
      };
    };
  };
}
