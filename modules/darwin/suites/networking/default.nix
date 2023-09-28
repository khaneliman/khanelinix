{ config
, lib
, options
, pkgs
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt;

  cfg = config.khanelinix.suites.networking;
in
{
  options.khanelinix.suites.networking = {
    enable =
      mkBoolOpt false "Whether or not to enable networking configuration.";
  };

  config = mkIf cfg.enable {
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
