{
  config,
  lib,
  ...
}:
let
  inherit (lib) types mkIf;
  inherit (lib.khanelinix) mkOpt;

  cfg = config.khanelinix.environments.home-network;
in
{
  options.khanelinix.environments.home-network = with types; {
    enable = lib.mkEnableOption "home network environment";
    serverHostname = mkOpt str "austinserver.local" "Home server hostname";
  };

  config = mkIf cfg.enable {
    # Darwin-specific network configuration can go here
    # For example: network location settings, NFS mounts in macOS style, etc.

    # SSH config for home server is handled in home-manager module
    # to keep it cross-platform
  };
}
