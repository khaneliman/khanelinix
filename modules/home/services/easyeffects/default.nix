{
  config,
  lib,

  ...
}:
let
  cfg = config.khanelinix.services.easyeffects;
in
{
  options.khanelinix.services.easyeffects = {
    enable = lib.mkEnableOption "easyeffects";
  };

  config = lib.mkIf cfg.enable {
    services.easyeffects = {
      enable = true;

      preset = "quiet";
    };

    xdg.configFile."easyeffects/output/quiet.json".source = ./quiet.json;
  };
}
