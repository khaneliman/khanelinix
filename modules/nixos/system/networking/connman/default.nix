{
  config,
  lib,

  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.khanelinix.system.networking;
in
{
  config = mkIf (cfg.enable && cfg.manager == "connman") {
    services.connman = {
      enable = true;

      networkInterfaceBlacklist = [
        "vmnet"
        "vboxnet"
        "virbr"
        "ifb"
        "ve"
      ]
      ++ lib.optionals config.khanelinix.services.tailscale.enable [ "tailscale*" ]
      ++ lib.optionals config.khanelinix.virtualisation.podman.enable [ "docker*" ];
    };
  };
}
