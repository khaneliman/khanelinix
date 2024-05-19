{ config, lib, ... }:
let
  inherit (lib) mkIf mkEnableOption;

  cfg = config.khanelinix.security.usbguard;
in
{
  options.khanelinix.security.usbguard = {
    enable = mkEnableOption "default usbguard configuration";
  };

  config = mkIf cfg.enable {
    services.usbguard = {
      IPCAllowedUsers = [
        "root"
        "${config.snowfallorg.user.name}"
      ];
      presentDevicePolicy = "allow";
      rules = ''
        allow with-interface equals { 08:*:* }

        # Reject devices with suspicious combination of interfaces
        reject with-interface all-of { 08:*:* 03:00:* }
        reject with-interface all-of { 08:*:* 03:01:* }
        reject with-interface all-of { 08:*:* e0:*:* }
        reject with-interface all-of { 08:*:* 02:*:* }
      '';
    };
  };
}
