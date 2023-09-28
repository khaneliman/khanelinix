{ config
, lib
, options
, pkgs
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt;

  cfg = config.khanelinix.apps.partitionmanager;
in
{
  options.khanelinix.apps.partitionmanager = {
    enable = mkBoolOpt false "Whether or not to enable partitionmanager.";
  };

  config =
    mkIf cfg.enable {
      environment.systemPackages = with pkgs; [
        partition-manager
        libsForQt5.kpmcore
      ];
    };
}
