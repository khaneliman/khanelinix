{
  config,
  lib,
  namespace,
  ...
}:
let

  cfg = config.${namespace}.services.ollama-ui;
in
{
  options.${namespace}.services.ollama-ui = {
    enable = lib.mkEnableOption "ollama ui";
  };

  config = lib.mkIf cfg.enable {
    services.nextjs-ollama-llm-ui = {
      enable = true;
      port = 3001;
    };
  };
}
