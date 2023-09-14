{ options
, config
, lib
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt;
  cfg = config.khanelinix.hardware.power;
in
{
  options.khanelinix.hardware.power = {
    enable =
      mkBoolOpt false
        "Whether or not to enable support for extra power devices.";
  };

  config = mkIf cfg.enable {
    services.upower = {
      enable = true;
      percentageLow = 25;
      percentageCritical = 10;
      percentageAction = 5;
    };
  };
}
