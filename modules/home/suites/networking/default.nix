{
  config,
  lib,
  pkgs,
  khanelinix-lib,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (khanelinix-lib) mkBoolOpt;

  cfg = config.khanelinix.suites.networking;
in
{
  options.khanelinix.suites.networking = {
    enable = mkBoolOpt false "Whether or not to enable networking configuration.";
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
      ++ lib.optionals pkgs.stdenv.isLinux [ iproute2 ];
  };
}
