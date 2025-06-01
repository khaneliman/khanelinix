{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.${namespace}.services.printing;
in
{
  options.${namespace}.services.printing = {
    enable = lib.mkEnableOption "printing support";
  };

  config = mkIf cfg.enable {
    services = {
      colord.enable = true;

      printing = {
        enable = true;
        browsing = true;

        # Use minimal drivers and rely on IPP Everywhere for modern printers
        drivers = with pkgs; [
          brlaser # Keep for legacy Brother printers if needed
        ];

        extraConf = ''
          LogLevel warn
          PageLogFormat

          # Specifies the maximum size of the log files before they are rotated.  The value "0" disables log rotation.
          MaxLogSize 0

          # Default error policy for printers
          ErrorPolicy retry-job

          # Show shared printers on the local network.
          BrowseLocalProtocols dnssd

          # Default authentication type, when authentication is required...
          DefaultAuthType Basic

          # Timeout after cupsd exits if idle (applied only if cupsd runs on-demand - with -l)
          IdleExitTimeout 60

          # Prefer IPP Everywhere for modern driverless printing
          # This helps reduce reliance on deprecated printer drivers
          CreateIPPPrinterQueues All

          # Define missing policy limits to silence warnings
          <Policy default>
            <Limit Validate-Job Print-Job Print-URI Create-Job Send-Document Send-URI Hold-Job Release-Job Restart-Job Purge-Jobs Set-Job-Attributes Create-Job-Subscription Renew-Subscription Cancel-Subscription Get-Notifications Reprocess-Job Cancel-Current-Job Suspend-Current-Job Resume-Job CUPS-Move-Job CUPS-Get-Document>
              Require user @SYSTEM
              Order deny,allow
            </Limit>

            <Limit Pause-Printer Resume-Printer Enable-Printer Disable-Printer Pause-Printer-After-Current-Job Hold-New-Jobs Release-Held-New-Jobs Deactivate-Printer Activate-Printer Restart-Printer Shutdown-Printer Startup-Printer Promote-Job Schedule-Job-After Cancel-Jobs CUPS-Add-Modify-Printer CUPS-Delete-Printer CUPS-Add-Modify-Class CUPS-Delete-Class CUPS-Set-Default CUPS-Add-Device CUPS-Delete-Device>
              AuthType Default
              Require user @SYSTEM
              Order deny,allow
            </Limit>

            <Limit Cancel-Job CUPS-Authenticate-Job>
              Require user @OWNER @SYSTEM
              Order deny,allow
            </Limit>

            <Limit All>
              Order deny,allow
            </Limit>

            # Add limits for operations that were showing warnings
            <Limit Validate-Job>
              Require user @OWNER @SYSTEM
              Order deny,allow
            </Limit>

            <Limit Cancel-Jobs>
              AuthType Default
              Require user @SYSTEM
              Order deny,allow
            </Limit>

            <Limit Cancel-My-Jobs>
              Require user @OWNER @SYSTEM
              Order deny,allow
            </Limit>

            <Limit Close-Job>
              Require user @OWNER @SYSTEM
              Order deny,allow
            </Limit>

            <Limit CUPS-Get-Document>
              Require user @OWNER @SYSTEM
              Order deny,allow
            </Limit>
          </Policy>
        '';
      };
    };
  };
}
