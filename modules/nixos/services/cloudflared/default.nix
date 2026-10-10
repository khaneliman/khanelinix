{
  lib,
  pkgs,
  config,

  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.khanelinix.services.cloudflared;
in
{
  options.khanelinix.services.cloudflared = {
    enable = lib.mkEnableOption "cloudflared";
  };

  config = mkIf cfg.enable {
    services.cloudflared = {
      # Cloudflared documentation
      # See: https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/
      enable = true;
      package = pkgs.cloudflared;

    };
  };
}
