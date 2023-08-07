{ options
, config
, lib
, ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.system.networking;
in
{
  options.khanelinix.system.networking = with types; {
    enable = mkBoolOpt false "Whether or not to enable networking support";
    hosts =
      mkOpt attrs { }
        "An attribute set to merge with <option>networking.hosts</option>";
  };

  config = mkIf cfg.enable {
    khanelinix.user.extraGroups = [ "networkmanager" ];

    networking = {
      hosts =
        {
          "127.0.0.1" = [ "local.test" ] ++ (cfg.hosts."127.0.0.1" or [ ]);
        }
        // cfg.hosts;
      nameservers = [ "1.1.1.1" "8.8.8.8" ];

      networkmanager = {
        enable = true;
        dhcp = "internal";
      };
    };

    # Fixes an issue that normally causes nixos-rebuild to fail.
    # https://github.com/NixOS/nixpkgs/issues/180175
    systemd.services.NetworkManager-wait-online.enable = false;
  };
}
