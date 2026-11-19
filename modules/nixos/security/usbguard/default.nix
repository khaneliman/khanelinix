{
  config,
  lib,

  ...
}:
let
  cfg = config.khanelinix.security.usbguard;
in
{
  options.khanelinix.security.usbguard = {
    enable = lib.mkEnableOption "default usbguard configuration";
  };

  config = lib.mkIf cfg.enable {
    services.usbguard = {
      enable = true;
      IPCAllowedUsers = [
        "root"
      ]
      ++ lib.optional (config.khanelinix.user.name != null) config.khanelinix.user.name;
      presentDevicePolicy = "allow";
      rules = ''
        allow with-interface equals { 09:*:* }
        allow with-interface equals { 03:*:* }
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
