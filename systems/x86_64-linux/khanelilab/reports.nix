{ config, ... }:
{
  services.nginx = {
    user = "media";
    group = "users";
    virtualHosts.github-triage = {
      root = "${config.services.hermes-agent.stateDir}/reports/github-triage";
      listen = [
        {
          addr = "0.0.0.0";
          port = 8098;
        }
        {
          addr = "127.0.0.1";
          port = 80;
        }
        {
          addr = "172.18.0.1";
          port = 80;
        }
      ];
    };
  };
  networking.firewall = {
    allowedTCPPorts = [ 8098 ];
    interfaces.khaneproxy.allowedTCPPorts = [ 80 ];
  };
  systemd.services.nginx = {
    requires = [ "khanelilab-container-networks.service" ];
    after = [ "khanelilab-container-networks.service" ];
    unitConfig.RequiresMountsFor = [ config.services.hermes-agent.stateDir ];
  };
}
