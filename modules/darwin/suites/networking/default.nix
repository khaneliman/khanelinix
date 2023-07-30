{ options
, config
, lib
, pkgs
, ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.suites.networking;
in
{
  options.khanelinix.suites.networking = with types; {
    enable =
      mkBoolOpt false "Whether or not to enable networking configuration.";
  };

  config = mkIf cfg.enable {
    khanelinix = {
      apps = {
        homebrew = enabled;
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
