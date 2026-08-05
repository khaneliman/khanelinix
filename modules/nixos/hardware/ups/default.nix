{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.khanelinix.hardware.ups;
in
{
  options.khanelinix.hardware.ups = {
    enable = lib.mkEnableOption "monitoring support for a USB-connected UPS via NUT";

    name = lib.mkOption {
      type = lib.types.str;
      default = "ups";
      description = "NUT identifier for the UPS.";
    };

    description = lib.mkOption {
      type = lib.types.str;
      default = "USB UPS";
      description = "Human-readable UPS description.";
    };
  };

  config = mkIf cfg.enable {
    power.ups = {
      enable = true;
      mode = "standalone";

      ups.${cfg.name} = {
        driver = "usbhid-ups";
        port = "auto";
        inherit (cfg) description;
      };

      users.upsmon = {
        upsmon = "primary";
        passwordFile = config.sops.secrets."nut-password".path;
      };

      upsmon.monitor.${cfg.name} = {
        user = "upsmon";
      };
    };

    sops.secrets."nut-password" = { };
  };
}
