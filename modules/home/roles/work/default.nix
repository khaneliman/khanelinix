{
  config,
  lib,

  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.khanelinix.roles.work;
in
{
  options.khanelinix.roles.work = {
    enable = lib.mkEnableOption "work role";
  };

  config = mkIf cfg.enable {
    khanelinix.suites = lib.khanelinix.nested-default-attrs {
      business = {
        enable = true;
        annotationEnable = true;
        architectureEnable = true;
        azureDevOpsEnable = true;
        knowledgeEnable = true;
        planningEnable = true;
        publishingEnable = true;
      };
      common.enable = true;
      development = {
        enable = true;
        dockerEnable = true;
        kubernetesEnable = true;
      };
    };
  };
}
