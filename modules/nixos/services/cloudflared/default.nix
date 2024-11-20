{
  lib,
  pkgs,
  config,

  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.khanelinix) mkBoolOpt;

  cfg = config.khanelinix.services.cloudflared;
in
{
  options.khanelinix.services.cloudflared = {
    enable = mkBoolOpt false "Whether or not to configure cloudflared";
  };

  config = mkIf cfg.enable {
    # NOTE: future reference for adding assertions
    # assertions = [
    #   {
    #     assertion = cfg.autoconnect.enable -> cfg.autoconnect.key != "";
    #     message = "khanelinix.services.cloudflared.autoconnect.key must be set";
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
