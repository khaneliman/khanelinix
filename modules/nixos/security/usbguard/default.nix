{
  config,
  lib,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.security.usbguard;
in
{
  options.${namespace}.security.usbguard = {
    enable = lib.mkEnableOption "default usbguard configuration";
  };

  config = lib.mkIf cfg.enable {
    services.usbguard = {
      IPCAllowedUsers = [
        "root"
        "${config.snowfallorg.users.name}"
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
