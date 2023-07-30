{ options
, config
, lib
, pkgs
, ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.apps.partitionmanager;
in
{
  options.khanelinix.apps.partitionmanager = with types; {
    enable = mkBoolOpt false "Whether or not to enable partitionmanager.";
  };

  config =
    mkIf cfg.enable { environment.systemPackages = with pkgs; [ partition-manager libsForQt5.kpmcore ]; };
}
