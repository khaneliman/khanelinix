{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.services.open-webui;
in
{
  options.${namespace}.services.open-webui = {
    enable = mkBoolOpt false "Whether to enable ollama ui.";
  };

  config = lib.mkIf cfg.enable {
    services.open-webui = {
      enable = true;
      openFirewall = true;
    };
  };
}
