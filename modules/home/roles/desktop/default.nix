{
  config,
  lib,

  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.khanelinix) enabled;

  cfg = config.khanelinix.roles.desktop;
in
{
  options.khanelinix.roles.desktop = {
    enable = lib.mkEnableOption "desktop role";
  };

  config = mkIf cfg.enable {
    khanelinix.suites = {
      common = enabled;
      desktop = {
        enable = true;
        remoteDesktopEnable = true;
        fileManagementEnable = true;
      };
      business = {
        enable = true;
        officeEnable = true;
        pimEnable = true;
      };
      social = {
        enable = true;
      };
      music = {
        enable = true;
        managementEnable = true;
      };
      video = {
        enable = true;
      };
      photo = {
        enable = true;
      };
    };
  };
}
