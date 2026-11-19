{
  config,
  lib,

  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.khanelinix.roles.desktop;
in
{
  options.khanelinix.roles.desktop = {
    enable = lib.mkEnableOption "desktop role";
  };

  config = mkIf cfg.enable {
    khanelinix.suites = lib.khanelinix.nested-default-attrs {
      common.enable = true;
      desktop = {
        enable = true;
        remoteDesktopEnable = true;
        fileManagementEnable = true;
      };
      business = {
        enable = true;
        annotationEnable = true;
        architectureEnable = true;
        azureDevOpsEnable = true;
        knowledgeEnable = true;
        officeEnable = true;
        pimEnable = true;
        planningEnable = true;
        publishingEnable = true;
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
