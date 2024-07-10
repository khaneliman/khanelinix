{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt enabled;

  cfg = config.${namespace}.suites.networking;
in
{
  options.${namespace}.suites.networking = {
    enable = mkBoolOpt false "Whether or not to enable networking configuration.";
  };

  config = mkIf cfg.enable {
    khanelinix = {
      services = {
        tailscale = enabled;
      };

      system = {
        networking = enabled;
      };
    };

    environment.systemPackages = with pkgs; [
      # ifstat-legacy
      nmap
      openssh
      speedtest-cli
      ssh-copy-id
      wireguard-go
    ];
  };
}
