{
  config,
  lib,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.services.easyeffects;
in
{
  options.${namespace}.services.easyeffects = {
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
