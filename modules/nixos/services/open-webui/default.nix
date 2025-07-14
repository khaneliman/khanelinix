{
  config,
  lib,

  ...
}:
let

  cfg = config.khanelinix.services.open-webui;
in
{
  options.khanelinix.services.open-webui = {
    enable = lib.mkEnableOption "ollama ui";
  };

  config = lib.mkIf cfg.enable {
    services.open-webui = {
      enable = true;
      openFirewall = true;
    };
  };
}
