{ options
, config
, lib
, ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.hardware.bluetooth;
in
{
  options.khanelinix.hardware.bluetooth = with types; {
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
