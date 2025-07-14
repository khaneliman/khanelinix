{
  config,
  lib,

  ...
}:
let

  cfg = config.khanelinix.services.ollama-ui;
in
{
  options.khanelinix.services.ollama-ui = {
    enable = lib.mkEnableOption "ollama ui";
  };

  config = lib.mkIf cfg.enable {
    services.nextjs-ollama-llm-ui = {
      enable = true;
      port = 3001;
    };
  };
}
