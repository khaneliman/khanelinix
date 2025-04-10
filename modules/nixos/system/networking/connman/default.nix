{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.${namespace}.system.networking;
in
{
  config = mkIf (cfg.enable && cfg.manager == "connman") {
    services.connman = {
      enable = true;

      networkInterfaceBlacklist =
        [
          "vmnet"
          "vboxnet"
          "virbr"
          "ifb"
          "ve"
        ]
        ++ lib.optionals config.${namespace}.services.tailscale.enable [ "tailscale*" ]
        ++ lib.optionals config.${namespace}.virtualisation.podman.enable [ "docker*" ];
    };
  };
}
