{ config
, lib
, pkgs
, ...
}:
let
  inherit (lib) mkEnableOption mkIf;

  cfg = config.khanelinix.services.barrier;
in
{
  options.khanelinix.services.barrier = {
    enable = mkEnableOption "barrier";

  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ barrier ];

    networking.firewall = {
      allowedTCPPorts = [ 24800 ];
    };
  };
}
