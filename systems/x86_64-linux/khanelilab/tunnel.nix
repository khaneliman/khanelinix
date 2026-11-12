{
  config,
  lib,
  pkgs,
  ...
}:
{
  # The live tunnel is remotely managed; a local catch-all would discard its routes.
  services.cloudflared.enable = lib.mkForce false;

  # The remote ingress rules reference this exact connector-local CA path.
  environment.etc."cloudflared/certs/origin_ca_rsa_root.pem".source = pkgs.fetchurl {
    url = "https://developers.cloudflare.com/ssl/static/origin_ca_rsa_root.pem";
    hash = "sha256-kailVn76a/lBFiqoBrO6R2qt33hnZA5TBTs1+yJaXa4=";
  };

  sops.secrets."cloudflared/token" = {
    sopsFile = lib.getFile "secrets/khanelilab/services.yaml";
    key = "cloudflared-token";
    restartUnits = [ "cloudflared-tunnel.service" ];
  };

  systemd.services.cloudflared-tunnel = {
    description = "Remotely managed Cloudflare tunnel";
    wantedBy = [ "multi-user.target" ];
    requires = [ "khanelilab-container-networks.service" ];
    after = [
      "network-online.target"
      "khanelilab-container-networks.service"
    ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      DynamicUser = true;
      LoadCredential = [ "token:${config.sops.secrets."cloudflared/token".path}" ];
      ExecStart = "${lib.getExe pkgs.cloudflared} tunnel --no-autoupdate run --token-file %d/token";
      Restart = "on-failure";
      RestartSec = 5;
    };
  };
}
