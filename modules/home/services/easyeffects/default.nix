{ config, lib, ... }:
let
  inherit (lib) mkEnableOption mkIf;

  cfg = config.khanelinix.services.easyeffects;
in
{
  options.khanelinix.services.easyeffects = {
    enable = mkEnableOption "easyeffects";
  };

  config = mkIf cfg.enable {
    services.easyeffects = {
      enable = true;

      preset = "quiet";
    };

    xdg.configFile."easyeffects/output/quiet.json".source = ./quiet.json;
  };
}
