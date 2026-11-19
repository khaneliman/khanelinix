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
    enable = lib.mkEnableOption "Open WebUI";
    openFirewall = lib.mkEnableOption "opening the firewall for Open WebUI";
  };

  config = lib.mkIf cfg.enable {
    services.open-webui = {
      # Open WebUI documentation
      # See: https://docs.openwebui.com/
      enable = true;
      inherit (cfg) openFirewall;
    };
  };
}
