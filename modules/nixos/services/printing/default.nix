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

        logLevel = "warn";

        extraConf = ''
          # Specifies the maximum size of the log files before they are rotated.  The value "0" disables log rotation.
          MaxLogSize 0

          # Default error policy for printers
          ErrorPolicy retry-job

          # Show shared printers on the local network.
          BrowseLocalProtocols dnssd

          # Timeout after cupsd exits if idle (applied only if cupsd runs on-demand - with -l)
          IdleExitTimeout 60
        '';
      };
    };
  };
}
