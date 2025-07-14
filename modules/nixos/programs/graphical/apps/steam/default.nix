{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.khanelinix.programs.graphical.apps.steam;
in
{
  options.khanelinix.programs.graphical.apps.steam = {
    enable = lib.mkEnableOption "support for Steam";
  };

  config = mkIf cfg.enable {
    environment = {
      systemPackages = with pkgs; [ steamtinkerlaunch ];
    };

    hardware.steam-hardware.enable = true;

    programs.steam = {
      enable = true;
      extest.enable = true;
      localNetworkGameTransfers.openFirewall = true;
      protontricks.enable = true;
      remotePlay.openFirewall = true;

      extraCompatPackages = [ pkgs.proton-ge-bin ];
    };
  };
}
