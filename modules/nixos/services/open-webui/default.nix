{
  config,
  lib,
  namespace,
  ...
}:
let

  cfg = config.${namespace}.services.open-webui;
in
{
  options.${namespace}.services.open-webui = {
    enable = lib.mkEnableOption "ollama ui";
  };

  config = lib.mkIf cfg.enable {
    services.open-webui = {
      enable = true;
      openFirewall = true;
    };
  };
}
