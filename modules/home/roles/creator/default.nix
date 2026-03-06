{
  config,
  lib,

  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.khanelinix.roles.creator;
in
{
  options.khanelinix.roles.creator = {
    enable = lib.mkEnableOption "creator role";
  };

  config = mkIf cfg.enable {
    khanelinix.suites = {
      art = {
        enable = true;
        threeDimensionalEnable = true;
        printingEnable = true;
      };
      photo = {
        enable = true;
        editingEnable = true;
      };
      video = {
        enable = true;
        editingEnable = true;
        discEnable = true;
        broadcastingEnable = true;
      };
      music = {
        enable = true;
        productionEnable = true;
      };
    };
  };
}
