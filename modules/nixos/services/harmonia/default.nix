{
  config,
  lib,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;

  cfg = config.khanelinix.services.harmonia;
in
{
  options.khanelinix.services.harmonia = {
    enable = mkEnableOption "Harmonia binary cache service";

    port = mkOption {
      type = types.port;
      default = 5000;
      description = "Port to bind Harmonia binary cache to.";
    };

    signKeyPath = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Path to the secret key used for signing binary cache store paths.";
    };

    openFirewall = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to open the Harmonia port in the firewall.";
    };
  };

  config = mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [ cfg.port ];

    services.harmonia = {
      cache = {
        enable = true;
        settings.bind = "[::]:${toString cfg.port}";
        signKeyPaths = mkIf (cfg.signKeyPath != null) [ cfg.signKeyPath ];
      };
    };
  };
}
