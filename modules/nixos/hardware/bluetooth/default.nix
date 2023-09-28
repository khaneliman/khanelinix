{ config
, lib
, options
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt;

  cfg = config.khanelinix.hardware.bluetooth;
in
{
  options.khanelinix.hardware.bluetooth = {
    enable =
      mkBoolOpt false
        "Whether or not to enable support for extra bluetooth devices.";
  };

  config = mkIf cfg.enable {
    hardware.bluetooth = {
      enable = true;
    };

    services.blueman = {
      enable = true;
    };
  };
}
