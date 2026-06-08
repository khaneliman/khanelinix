{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.khanelinix.hardware.keyboards.advantage360;
in
{
  options.khanelinix.hardware.keyboards.advantage360 = {
    enable = lib.mkEnableOption "Kinesis Advantage360 Pro firmware tooling";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.khanelinix.flash-adv360 ];
  };
}
