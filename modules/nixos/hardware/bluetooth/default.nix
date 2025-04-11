{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.${namespace}.hardware.bluetooth;
in
{
  options.${namespace}.hardware.bluetooth = {
    enable = lib.mkEnableOption "support for extra bluetooth devices";
    autoConnect = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to automatically connect to paired devices on startup";
    };
  };

  config = mkIf cfg.enable {
    hardware.bluetooth = {
      enable = true;

      package = pkgs.bluez-experimental;
      powerOnBoot = false;

      settings = {
        General = {
          Experimental = true;
          JustWorksRepairing = "always";
          KernelExperimental = true;
          MultiProfile = "multiple";
        };
        Policy = {
          AutoEnable = cfg.autoConnect;
          ReconnectAttempts = if cfg.autoConnect then 7 else 0;
          ReconnectIntervals = "1,2,4,8,16,32,64";
        };
      };
    };

    boot.kernelParams = [ "btusb" ];

    services.blueman = {
      enable = true;
    };
  };
}
