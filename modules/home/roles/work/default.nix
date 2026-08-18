{
  config,
  lib,

  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.khanelinix) enabled;

  cfg = config.khanelinix.roles.work;
in
{
  options.khanelinix.roles.work = {
    enable = lib.mkEnableOption "work role";
  };

  config = mkIf cfg.enable {
    khanelinix.suites = {
      business = {
        enable = true;
        annotationEnable = true;
        architectureEnable = true;
        knowledgeEnable = true;
        planningEnable = true;
        publishingEnable = true;
      };
      common = enabled;
      development = {
        enable = true;
        dockerEnable = true;
        kubernetesEnable = true;
      };
    };
  };
}
