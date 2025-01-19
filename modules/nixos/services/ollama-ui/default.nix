{
  config,
  khanelinix-lib,
  lib,
  namespace,
  ...
}:
let
  inherit (khanelinix-lib) mkBoolOpt;

  cfg = config.${namespace}.services.ollama-ui;
in
{
  options.${namespace}.services.ollama-ui = {
    enable = mkBoolOpt false "Whether to enable ollama ui.";
  };

  config = lib.mkIf cfg.enable {
    services.nextjs-ollama-llm-ui = {
      enable = true;
      port = 3001;
    };
  };
}
