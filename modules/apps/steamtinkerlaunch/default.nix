{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.khanelinix.apps.steamtinkerlaunch;

  inherit (lib) mkIf mkEnableOption;
in {
  options.khanelinix.apps.steamtinkerlaunch = {
    enable = mkEnableOption "Steam Tinker Launch";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      steamtinkerlaunch
    ];
  };
}
