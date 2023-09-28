{ config
, lib
, ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  inherit (lib.internal) enabled;

  cfg = config.khanelinix.cli-apps.home-manager;
in
{
  options.khanelinix.cli-apps.home-manager = {
    enable = mkEnableOption "home-manager";
  };

  config = mkIf cfg.enable {
    programs.home-manager = enabled;
  };
}
