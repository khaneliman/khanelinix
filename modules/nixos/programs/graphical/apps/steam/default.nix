{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.khanelinix) suiteProfileIncludes;

  cfg = config.khanelinix.programs.graphical.apps.steam;
  gamesCfg = config.khanelinix.suites.games;
  maximal = suiteProfileIncludes config gamesCfg "maximal";
in
{
  options.khanelinix.programs.graphical.apps.steam = {
    enable = lib.mkEnableOption "support for Steam";
  };

  config = mkIf cfg.enable {
    environment = {
      systemPackages = with pkgs; lib.optionals maximal [ steamtinkerlaunch ];
    };

    hardware.steam-hardware.enable = true;

    programs.steam = {
      # Steam/Proton documentation
      # See: https://github.com/ValveSoftware/Proton
      enable = true;
      extest.enable = true;
      localNetworkGameTransfers.openFirewall = true;
      protontricks.enable = lib.mkDefault maximal;
      remotePlay.openFirewall = true;

      extraCompatPackages = lib.optionals maximal [ pkgs.proton-ge-bin ];
    };
  };
}
