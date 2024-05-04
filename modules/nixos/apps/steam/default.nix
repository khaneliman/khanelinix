{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt;

  cfg = config.khanelinix.apps.steam;
in
{
  options.khanelinix.apps.steam = {
    enable = mkBoolOpt false "Whether or not to enable support for Steam.";
  };

  config = mkIf cfg.enable {
    environment = {
      systemPackages = with pkgs; [ steamtinkerlaunch ];
    };

    programs.steam = {
      enable = true;
      remotePlay.openFirewall = true;

      extraCompatPackages = [ pkgs.proton-ge-bin.steamcompattool ];
    };

    hardware.steam-hardware.enable = true;
  };
}
