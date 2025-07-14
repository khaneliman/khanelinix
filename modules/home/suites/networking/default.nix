{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.khanelinix.suites.networking;
in
{
  options.khanelinix.suites.networking = {
    enable = lib.mkEnableOption "networking configuration";
  };

  config = mkIf cfg.enable {

    home.packages =
      with pkgs;
      [
        nmap
        openssh
        speedtest-cli
        ssh-copy-id
      ]
      ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [ iproute2 ];
  };
}
