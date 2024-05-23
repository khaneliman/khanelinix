{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;

  cfg = config.${namespace}.services.barrier;
in
{
  options.${namespace}.services.barrier = {
    enable = mkEnableOption "barrier";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ barrier ];

    networking.firewall = {
      allowedTCPPorts = [ 24800 ];
    };
  };
}
