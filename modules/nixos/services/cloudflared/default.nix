{
  lib,
  pkgs,
  config,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.${namespace}.services.cloudflared;
in
{
  options.${namespace}.services.cloudflared = {
    enable = lib.mkEnableOption "cloudflared";
  };

  config = mkIf cfg.enable {
    # NOTE: future reference for adding assertions
    # assertions = [
    #   {
    #     assertion = cfg.autoconnect.enable -> cfg.autoconnect.key != "";
    #     message = "${namespace}.services.cloudflared.autoconnect.key must be set";
    #   }
    # ];

    services.cloudflared = {
      enable = true;
      package = pkgs.cloudflared;

      tunnels = {
        "KHANELIMANCOM" = {
          # TODO: replace with sops secret
          credentialsFile = "REPLACEME";
          default = "http_status:404";
          ingress = {
            "khaneliman.com" = {
              # TODO: replace with sops secret
              service = "https://ip:port";
              originRequest = {
                noTLSVerify = true;
                originServerName = "khaneliman.com";
              };
            };
          };
        };
      };
    };
  };
}
