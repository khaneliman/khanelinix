{
  config,
  lib,

  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.khanelinix.hardware.fans;
in
{
  options.khanelinix.hardware.fans = {
    enable = lib.mkEnableOption "support for fan control";
  };

  config = mkIf cfg.enable {
    programs.coolercontrol = {
      enable = true;
      # TODO: declaratively disable `liquidctl` conflicts with `openrgb` and breaks lighting
    };
  };
}
