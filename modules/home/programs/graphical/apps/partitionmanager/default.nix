{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.programs.graphical.apps.partitionmanager;
in
{
  options.${namespace}.programs.graphical.apps.partitionmanager = {
    enable = mkBoolOpt false "Whether or not to enable partitionmanager.";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      partition-manager
      libsForQt5.kpmcore
    ];
  };
}
