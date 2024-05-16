{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt;

  cfg = config.khanelinix.programs.graphical.apps.partitionmanager;
in
{
  options.khanelinix.programs.graphical.apps.partitionmanager = {
    enable = mkBoolOpt false "Whether or not to enable partitionmanager.";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      partition-manager
      libsForQt5.kpmcore
    ];
  };
}
