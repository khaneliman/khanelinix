{ options
, config
, lib
, pkgs
, ...
}:
let
  inherit (lib) types mkIf;
  inherit (lib.internal) mkBoolOpt;
  cfg = config.khanelinix.apps.partitionmanager;
in
{
  options.khanelinix.apps.partitionmanager = with types; {
    enable = mkBoolOpt false "Whether or not to enable partitionmanager.";
  };

  config =
    mkIf cfg.enable { environment.systemPackages = with pkgs; [ partition-manager libsForQt5.kpmcore ]; };
}
