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

  cfg = config.${namespace}.programs.graphical.apps.steam;
in
{
  options.${namespace}.programs.graphical.apps.steam = {
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
